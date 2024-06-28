import ssl
import os

# URL для скачивания сертификата
url = "https://dckr-1.int.ops.cldx.ru/"
host = "dckr-1.int.ops.cldx.ru"
port = 443

# Путь к файлу сертификата
certificate_file = "dckr-1.der"

# Создание SSL контекста
context = ssl.create_default_context()

# Установка параметра, чтобы контролировать проверку сертификата
context.check_hostname = False
context.verify_mode = ssl.CERT_NONE

# Установка соединения с веб-сайтом и получение сертификата
certificate = ssl.get_server_certificate((host, port))

# Сохранение сертификата в файл
with open(certificate_file, "wb") as file:
    file.write(ssl.PEM_cert_to_DER_cert(certificate))

# Путь к keystore файлу
keystore_path = "C:\\Users\\sasakinme\\.jdks\\corretto-17.0.9\\lib\\security\\cacerts"

# Команда для удаления существующего сертификата из keystore
delete_command = f'keytool -delete -alias ssldckr-1 -keystore "{keystore_path}"'

# Команда для импорта нового сертификата в keystore
import_command = f'keytool -importcert -file "{certificate_file}" -alias ssldckr-1 -storepass changeit -keystore "{keystore_path}"'

# Выполнение команд через командную строку
os.system(delete_command)
os.system(import_command)