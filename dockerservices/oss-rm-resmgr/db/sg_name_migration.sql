DO $$
    DECLARE
        rec                       RECORD;
        rec_new                   RECORD;
        sg_type                   RECORD;
        user_resource_category_id uuid;
        updated_rules JSONB := '[]'::jsonb;  -- Инициализируем пустой JSONB массив
        security_rule             JSONB;
        security_group_id         UUID;
        security_group_name       TEXT;
    BEGIN

        -- Fetch resource types
        SELECT *
        INTO sg_type
        FROM resource_type
        WHERE sysname = 'NetworkSecurityGroup';

        -- Fetch dependency and user resource category IDs
        SELECT id
        INTO user_resource_category_id
        FROM resource_manager.resource_category
        WHERE sysname = 'USER_RESOURCE';

        -- Loop through resources
        FOR rec IN
            SELECT *
            FROM resource res
            WHERE res.resource_type_id = sg_type.id
              AND res.specification IS NOT NULL
              AND res.resource_category_id = user_resource_category_id
            LOOP

                updated_rules := '[]'::jsonb;
                -- Log resource ID and name
                RAISE NOTICE '------------------------------------------------------------------------------------------';
                RAISE NOTICE 'Updating resource ID: %, Name: %', rec.id, rec.name;
                RAISE NOTICE 'Updating resource rules: %',  rec.specification;

                FOR security_rule IN
                    SELECT *
                    FROM jsonb_array_elements(rec.specification -> 'securityGroupRules')
                    LOOP
                        -- Проверяем наличие поля securityGroupId
                        IF security_rule ->> 'securityGroupId' IS NOT NULL THEN
                            security_group_id := security_rule ->> 'securityGroupId';

                            -- Получаем имя securityGroup по securityGroupId
                            SELECT name INTO security_group_name
                            FROM resource
                            WHERE id = security_group_id;

                            -- Обновляем securityGroupName в элементе
                            security_rule := jsonb_set(security_rule, '{securityGroupName}', to_jsonb(security_group_name));
                        END IF;

                        -- Добавляем обновленный элемент в массив
                        updated_rules := updated_rules || jsonb_build_array(security_rule);
                    END LOOP;

                -- Проверяем, что updated_rules не пустой и отличается от текущего значения
                IF updated_rules IS NOT NULL AND updated_rules <> '[]'::jsonb AND
                   (rec.specification -> 'securityGroupRules') <> updated_rules THEN
                    -- Обновляем запись в таблице resource
                    UPDATE resource
                    SET specification = jsonb_set(rec.specification, '{securityGroupRules}', updated_rules)
                    WHERE id = rec.id;

                    SELECT *
                    INTO rec_new
                    FROM resource
                    WHERE id = rec.id;

                    RAISE NOTICE 'New resource resource ID: %, Name: %, Specification: %', rec_new.id, rec_new.name, rec_new.specification;

                ELSE
                    -- Логируем пропуск изменений
                    RAISE NOTICE 'Skipping update for resource ID: %, no changes detected.', rec.id;
                END IF;

            END LOOP;
    END
$$;