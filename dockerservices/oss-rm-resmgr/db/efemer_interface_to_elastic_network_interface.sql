DO $$
    DECLARE
        rec RECORD;
        elastic_type RECORD;
        sg_type RECORD;
        public_type RECORD;
        vm_rec RECORD;
        subnet_rec RECORD;
        elastic_id uuid;
        dependency_type_id uuid;
        user_resource_category_id uuid;
        dependency_elastic_subnet_id uuid;
        security_groups jsonb;
        elasticNetworkInterfaces jsonb;
        sg_rec RECORD;
        public_rec RECORD;
        json_spec jsonb;
    BEGIN
        -- Create temporary table for migration to openstack_adapter.resource_map
        CREATE TABLE IF NOT EXISTS resource_manager.os_dependency_resource_map (
                                                                                   id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
                                                                                   resource_id uuid NOT NULL,
                                                                                   cluster_id varchar(255) NOT NULL,
                                                                                   dependency_id uuid NOT NULL,
                                                                                   created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
                                                                                   created_by varchar(255) NOT NULL,
                                                                                   UNIQUE (cluster_id, dependency_id),
                                                                                   UNIQUE (resource_id, cluster_id)
        );

        -- Fetch resource types
        SELECT * INTO elastic_type FROM resource_type WHERE sysname = 'ElasticNetworkInterface';
        SELECT * INTO sg_type FROM resource_type WHERE sysname = 'NetworkSecurityGroup';
        SELECT * INTO public_type FROM resource_type WHERE sysname = 'PublicIPAddress';

        -- Fetch dependency and user resource category IDs
        SELECT id INTO dependency_type_id FROM resource_manager.resource_dependency_type WHERE sysname = 'connectedTo';
        SELECT id INTO user_resource_category_id FROM resource_manager.resource_category WHERE sysname = 'USER_RESOURCE';

        -- Loop through resources
        FOR rec IN
            WITH vm_to_skip AS (
                SELECT vm_id
                FROM resource_management.resource_manager.network_interface_view niv
                WHERE is_elastic = false
                  AND resource_category_id = user_resource_category_id
                GROUP BY vm_id
                HAVING COUNT(*) > 1
            )
            SELECT
                dependency_subnet.id,
                resource.cloud_id,
                resource.resource_group_id,
                resource.resource_category_id,
                CASE
                    WHEN r_status.sysname::text = ANY (ARRAY ['ACTIVE', 'STARTING', 'STOPPING', 'REBOOTING', 'SUSPENDING', 'RESUMING', 'STOPPED', 'SUSPENDED'])
                        THEN r_status_in_use.id
                    ELSE r_status_error.id
                    END AS resource_status_id,
                resource.name AS vm_name,
                resource.id AS vm_id,
                (network_interfaces.value ->> 'subnetId')::uuid AS subnet_id,
                ip_address.value ->> 'ipAddress' AS ip_address,
                resource.created_at,
                resource.created_by,
                resource.stack_id AS stack_id
            FROM resource
                     JOIN resource_status r_status ON r_status.id = resource.resource_status_id
                     JOIN resource_category r_category ON r_category.sysname = 'USER_RESOURCE'
                     JOIN resource_status r_status_in_use ON r_status_in_use.sysname = 'IN_USE'
                     JOIN resource_status r_status_error ON r_status_error.sysname = 'ERROR'
                     JOIN resource_type r_type ON r_type.id = resource.resource_type_id
                     JOIN LATERAL jsonb_array_elements(resource.specification->'networkProfile'->'networkInterfaces') network_interfaces(value) ON (network_interfaces.value ->> 'subnetId') IS NOT NULL
                     JOIN LATERAL jsonb_array_elements(resource.current_state_specification -> 'addresses') addresses(value) ON (addresses.value ->> 'ipAddresses') IS NOT NULL
                     JOIN LATERAL jsonb_array_elements(addresses.value -> 'ipAddresses') ip_address(value) ON (ip_address.value ->> 'distributionType') = 'fixed' AND NOT EXISTS (
                SELECT 1
                FROM resource_dependency rd
                         JOIN resource r_pip_1 ON r_pip_1.id = rd.dependency_resource_id AND r_pip_1.current_state_specification IS NOT NULL
                         JOIN resource_type rt ON rt.id = r_pip_1.resource_type_id AND rt.sysname = 'ElasticNetworkInterface'
                WHERE rd.resource_id = resource.id AND (r_pip_1.specification ->> 'fixedIp') = (ip_address.value ->> 'ipAddress')
            )
                     JOIN resource_dependency dependency_subnet ON dependency_subnet.resource_id = resource.id AND dependency_subnet.dependency_resource_id::text = (network_interfaces.value ->> 'subnetId')
            WHERE r_type.sysname = 'VirtualMachineInstance'
              AND resource.current_state_specification IS NOT NULL
              AND resource_category_id = user_resource_category_id
              AND resource.id NOT IN (SELECT vm_id FROM vm_to_skip)
            LOOP
                -- Fetch VM record
                SELECT * INTO vm_rec FROM resource_manager.resource WHERE id = rec.vm_id;

                -- Skip action if VM belongs to a user stack
                IF vm_rec.stack_id IS NOT NULL THEN
                    CONTINUE;
                END IF;

                -- Fetch subnet record
                SELECT * INTO subnet_rec FROM resource_manager.resource WHERE id = rec.subnet_id;

                elastic_id := gen_random_uuid();
                security_groups := vm_rec.specification->'networkProfile'->'securityGroups';
                elasticNetworkInterfaces := COALESCE(vm_rec.specification->'networkProfile'->'elasticNetworkInterfaces', '[]'::jsonb);

                -- Build JSON specification for elastic interface
                IF security_groups IS NOT NULL THEN
                    json_spec := jsonb_build_object(
                            'fixedIp', rec.ip_address,
                            'subnetId', rec.subnet_id,
                            'networkId', subnet_rec.specification->'networkId',
                            'securityGroups', security_groups,
                            'portSecurityEnabled', true
                                 );
                ELSE
                    json_spec := jsonb_build_object(
                            'fixedIp', rec.ip_address,
                            'subnetId', rec.subnet_id,
                            'networkId', subnet_rec.specification->'networkId',
                            'portSecurityEnabled', false
                                 );
                END IF;

                -- Insert elastic interface into resource
                INSERT INTO resource_manager.resource (
                    id, cloud_id, resource_type_id, resource_group_id, resource_category_id,
                    resource_status_id, name, description, specification, current_state_specification, created_by, version,
                    system_service_id, user_status_id, availability_zone_id, region_id
                )
                VALUES (
                           elastic_id, vm_rec.cloud_id, elastic_type.id, vm_rec.resource_group_id, subnet_rec.resource_category_id,
                           rec.resource_status_id, rec.vm_name || '-' || FLOOR(RANDOM() * 10000)::int || '-elastic', '', json_spec,
                           subnet_rec.created_by, subnet_rec.version, subnet_rec.system_service_id, subnet_rec.user_status_id,
                           subnet_rec.availability_zone_id, subnet_rec.region_id
                       );

                RAISE NOTICE 'Inserted elasticNetworkInterface into resource with id %', elastic_id;

                -- Update dependency for interface and subnet
                SELECT id INTO dependency_elastic_subnet_id
                FROM resource_manager.resource_dependency
                WHERE resource_id = rec.vm_id AND dependency_resource_id = rec.subnet_id;

                UPDATE resource_manager.resource_dependency
                SET resource_id = elastic_id
                WHERE id = dependency_elastic_subnet_id;

                RAISE NOTICE 'Inserted resource_dependency (elasticId, subnetId).';

                INSERT INTO  resource_manager.resource_dependency (id, resource_id, dependency_resource_id, created_at, created_by, resource_dependency_type_id, is_hard)
                VALUES (gen_random_uuid(), vm_rec.id, elastic_id, vm_rec.created_at, vm_rec.created_by, dependency_type_id, true);

                RAISE NOTICE 'Inserted resource_dependency (vmId, elasticId).';

                -- Update security groups dependencies
                FOR sg_rec IN
                    SELECT rd.id FROM resource_manager.resource_dependency rd
                                          JOIN resource_manager.resource r ON rd.dependency_resource_id = r.id
                    WHERE r.resource_type_id = sg_type.id AND rd.resource_id = vm_rec.id
                    LOOP
                        UPDATE resource_manager.resource_dependency
                        SET resource_id = elastic_id
                        WHERE id = sg_rec.id;
                        RAISE NOTICE 'Updated security groups into resource_dependency (elasticId, securityGroupId).';
                    END LOOP;

                -- Update public IP dependencies
                FOR public_rec IN
                    SELECT rd.id FROM resource_manager.resource_dependency rd
                                          JOIN resource_manager.resource r ON rd.dependency_resource_id = r.id
                    WHERE r.resource_type_id = public_type.id AND rd.resource_id = vm_rec.id
                    LOOP
                        UPDATE resource_manager.resource_dependency
                        SET resource_id = elastic_id
                        WHERE id = public_rec.id;
                        RAISE NOTICE 'Updated public IP into resource_dependency (elasticId, publicIpId).';
                    END LOOP;

                IF security_groups IS NOT NULL THEN

                    -- обновить спецификацию ВМ
                    UPDATE resource_manager.resource
                    SET specification = jsonb_set(
                            specification::jsonb,
                            '{networkProfile}',
                            jsonb_build_object(
                                    'elasticNetworkInterfaces',
                                    elasticNetworkInterfaces || to_jsonb(elastic_id),
                                    'securityGroups',
                                    security_groups
                            )
                                        )
                    WHERE specification @> '{"networkProfile": {"networkInterfaces": []}}'
                      AND id = vm_rec.id;
                ELSE
                    -- обновить спецификацию ВМ
                    UPDATE resource_manager.resource
                    SET specification = jsonb_set(
                            specification::jsonb,
                            '{networkProfile}',
                            jsonb_build_object(
                                    'elasticNetworkInterfaces',
                                    elasticNetworkInterfaces || to_jsonb(elastic_id)
                            )
                                        )
                    WHERE specification @> '{"networkProfile": {"networkInterfaces": []}}'
                      AND id = vm_rec.id;
                END IF;

                -- Save elastic interface IDs and dependencies for further migration
                INSERT INTO resource_manager.os_dependency_resource_map (
                    id, resource_id, cluster_id, dependency_id, created_by
                )
                VALUES (
                           gen_random_uuid(), elastic_id, vm_rec.system_service_id,
                           dependency_elastic_subnet_id, rec.created_by
                       );
            END LOOP;
    END
$$;