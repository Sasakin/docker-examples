import os
from pydub import AudioSegment
import whisper


# Функция для распознавания речи из файла WAV
def recognize_speech_from_wav(wav_file):
    # Загрузка модели Whisper
    model = whisper.load_model("base")  # Вы можете выбрать 'tiny', 'base', 'small', 'medium', 'large'

    # Распознавание речи
    result = model.transcribe(wav_file, language='ru')
    return result['text']

# Основная функция
def main(mp3_file):
    #if not os.path.exists(mp3_file):
     #   print("Файл не найден!")
     #   return

    wav_file = "video.wav"  #convert_mp3_to_wav(mp3_file)
    text = recognize_speech_from_wav(wav_file)
    print("Распознанный текст:")
    print(text)

# Пример использования
if __name__ == "__main__":
    mp3_file_path = "video.mp3"  # Укажите путь к вашему MP3 файлу
    main(mp3_file_path)