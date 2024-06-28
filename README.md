1. Импортировать сертификат с https://nxs-1.int.ops.x/ в формате *.der
2. Добавить в хранилище ключей с помощью команды
3. keytool -importcert -file vault-https-test.der -alias sslvaulttest -storepass changeit -keystore C:\Users\sasakinme\.jdks\corretto-17.0.9\lib\security\cacerts
4. keytool -importcert -file k8s.der -alias sslk8stest -storepass changeit -keystore C:\Users\sasakinme\.jdks\corretto-17.0.9\lib\security\cacerts
5. keytool -importcert -file vault-https.der -alias sslvaultdev -storepass changeit -keystore C:\Users\sasakinme\.jdks\corretto-17.0.9\lib\security\cacerts
6. keytool -list -keystore C:\Users\sasakinme\.jdks\corretto-17.0.9\lib\security\cacerts
7. keytool -delete -alias sslos-10 -keystore C:\Users\sasakinme\.jdks\corretto-17.0.9\lib\security\cacerts
8. keytool -importcert -file vault-https.der -alias sslvaultdev -storepass changeit -keystore C:\Users\sasakinme\.jdks\corretto-17.0.9\lib\security\cacerts
8. keytool -importcert -file os-10.cp.dev.x.der -alias sslos-10 -storepass changeit -keystore C:\Users\sasakinme\.jdks\corretto-17.0.9\lib\security\cacerts
9. keytool -importcert -file os-1-api.cp.dev.x.der -alias sslos-1-api -storepass changeit -keystore C:\Users\sasakinme\.jdks\corretto-17.0.9\lib\security\cacerts
10. keytool -importcert -file os-4.cp.dev.x.der -alias sslos-4 -storepass changeit -keystore C:\Users\sasakinme\.jdks\corretto-17.0.9\lib\security\cacerts
11. keytool -importcert -file nxs-1.int.ops.x.der -alias nxs-1 -storepass changeit -keystore C:\Users\sasakinme\.jdks\corretto-17.0.9\lib\security\cacerts


## dellete:
keytool -delete -alias sslvaultdev -keystore C:\Users\sasakinme\.jdks\corretto-17.0.9\lib\security\cacerts
keytool -delete -alias sslos-10 -keystore C:\Users\sasakinme\.jdks\corretto-17.0.9\lib\security\cacerts
keytool -delete -alias sslos-4 -keystore C:\Users\sasakinme\.jdks\corretto-17.0.9\lib\security\cacerts
keytool -delete -alias nxs-1 -keystore C:\Users\sasakinme\.jdks\corretto-17.0.9\lib\security\cacerts
keytool -delete -alias sslnexus -keystore C:\Users\sasakinme\.jdks\corretto-17.0.9\lib\security\cacerts 