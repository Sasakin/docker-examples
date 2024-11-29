import requests

# URL страницы, которую вы хотите скопировать
url = 'https://schoolterebenin.getcourse.ru/cms/system/login'  # Замените на нужный URL

# Получение содержимого страницы
response = requests.get(url, verify=False)

# Проверка успешности запроса
if response.status_code == 200:
    # Сохранение содержимого в файл
    with open('page.html', 'w', encoding='utf-8') as file:
        file.write(response.text)
    print("HTML-страница успешно скопирована!")
else:
    print(f"Ошибка при получении страницы: {response.status_code}")