from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
import requests
import time
import os

# Получение данных из переменных окружения
username = os.getenv('VIDEO_USERNAME')  # Переменная окружения для логина
password = os.getenv('VIDEO_PASSWORD')  # Переменная окружения для пароля
video_page_url = os.getenv('VIDEO_PAGE_URL')  # Переменная окружения для URL страницы с видео



# Запуск браузера
driver = webdriver.Chrome()  # Или другой драйвер, если используете другой браузер
driver.get(os.getenv('VIDEO_PAGE_HOST'))  # Замените на URL входа в GetCourse

# Авторизация
time.sleep(2)  # Подождите, чтобы страница загрузилась
username_input = driver.find_element(By.NAME, 'login')  # Замените на правильный селектор
password_input = driver.find_element(By.NAME, 'password')  # Замените на правильный селектор

username_input.send_keys(username)
password_input.send_keys(password)
password_input.send_keys(Keys.RETURN)

# Подождите, пока страница загрузится после входа
time.sleep(5)

# Переход на страницу с видео
driver.get(video_page_url)
time.sleep(5)  # Подождите, чтобы страница загрузилась

# Найдите элемент видео и получите ссылку на видео
video_element = driver.find_element(By.TAG_NAME, 'video')  # Замените на правильный селектор
video_url = video_element.get_attribute('src')

# Скачивание видео
response = requests.get(video_url)

with open('video.mp4', 'wb') as file:
    file.write(response.content)

print("Видео скачано успешно!")

# Закрыть браузер
driver.quit()