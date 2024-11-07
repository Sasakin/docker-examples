from telethon import TelegramClient
import asyncio

# Замените эти значения на свои
api_id = '21812871'
api_hash = 'c6a6cd2c83fd4c945e6526292edac2e4'
channel_username = '@JuliaKhadartseva' #'@zxcsadinside'  # Например, '@my_channel' https://t.me/zxcsadinside

# Создаем клиент
client = TelegramClient('session_name', api_id, api_hash)

async def main():
    await client.start()

    # Получаем объект канала
    channel = await client.get_entity(channel_username)
    # Счетчик для строк и номер файла
    title = 'post'
    line_count = 0
    file_number = 1
    file_name = f'{title}_{file_number}.txt'

    # Получаем сообщения из канала
    async for message in client.iter_messages(channel):
        if message.text:  # Проверяем наличие текста и ссылки if message.text and 't.me' in message.text:
            print(message.text)  # Печатаем текст сообщения
            # Сохраняем в файл
            with open(file_name, 'a', encoding='utf-8') as f:
                f.write(message.text + '\n')

            line_count += 1

            if file_number == 5:
                break

                # Если достигли 2500 строк, создаем новый файл
            if line_count >= 500:
                file_number += 1
                file_name = f'{title}_{file_number}.txt'
                line_count = 0
# Запускаем асинхронную функцию
asyncio.run(main())