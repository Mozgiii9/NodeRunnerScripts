import aiohttp
import asyncio
import random
import logging
import sys
from datetime import datetime
from typing import List, Dict, Optional

# Настройка логирования
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
    handlers=[
        logging.StreamHandler(sys.stdout),
        logging.FileHandler('gaia_bot.log')
    ]
)
logger = logging.getLogger(__name__)

class GaiaBot:
    def __init__(self):
        self.url = f"https://{self.get_node_id()}.gaia.domains/v1/chat/completions"
        self.headers = {
            "accept": "application/json",
            "Content-Type": "application/json"
        }
        self.roles: List[str] = []
        self.phrases: List[str] = []
        self.session: Optional[aiohttp.ClientSession] = None
        self.retry_count = 3
        self.retry_delay = 5
        self.timeout = 60

    @staticmethod
    def get_node_id() -> str:
        """Получение ID ноды из конфигурации."""
        try:
            with open("config.txt", "r") as f:
                return f.readline().strip()
        except FileNotFoundError:
            logger.error("❌ Файл конфигурации не найден!")
            sys.exit(1)

    async def initialize(self) -> None:
        """Инициализация бота и загрузка необходимых данных."""
        try:
            self.roles = self.load_from_file("roles.txt")
            self.phrases = self.load_from_file("phrases.txt")
            self.session = aiohttp.ClientSession()
            logger.info("✅ Бот успешно инициализирован")
        except Exception as e:
            logger.error(f"❌ Ошибка инициализации: {e}")
            sys.exit(1)

    @staticmethod
    def load_from_file(file_name: str) -> List[str]:
        """Загрузка данных из файла с обработкой ошибок."""
        try:
            with open(file_name, "r") as file:
                return [line.strip() for line in file.readlines() if line.strip()]
        except FileNotFoundError:
            logger.error(f"❌ Файл {file_name} не найден!")
            sys.exit(1)

    def generate_message(self) -> List[Dict[str, str]]:
        """Генерация сообщений для отправки."""
        user_message = {
            "role": "user",
            "content": random.choice(self.phrases)
        }
        other_message = {
            "role": random.choice([r for r in self.roles if r != "user"]),
            "content": random.choice(self.phrases)
        }
        return [user_message, other_message]

    async def send_request(self, messages: List[Dict[str, str]]) -> None:
        """Отправка запроса к API с обработкой ошибок и повторными попытками."""
        for attempt in range(self.retry_count):
            try:
                async with self.session.post(
                    self.url,
                    json={"messages": messages},
                    headers=self.headers,
                    timeout=self.timeout
                ) as response:
                    if response.status == 200:
                        result = await response.json()
                        self.log_success(messages[0]["content"], result)
                        return
                    else:
                        logger.warning(f"⚠️ Попытка {attempt + 1}/{self.retry_count}: Статус {response.status}")
                        
            except asyncio.TimeoutError:
                logger.warning(f"⚠️ Попытка {attempt + 1}/{self.retry_count}: Таймаут")
            except Exception as e:
                logger.error(f"❌ Попытка {attempt + 1}/{self.retry_count}: Ошибка: {e}")
            
            if attempt < self.retry_count - 1:
                await asyncio.sleep(self.retry_delay)

    def log_success(self, question: str, result: Dict) -> None:
        """Логирование успешного ответа."""
        response = result["choices"][0]["message"]["content"]
        logger.info(f"📤 Вопрос: {question}")
        logger.info(f"📥 Ответ: {response}")
        logger.info("=" * 50)

    async def run(self) -> None:
        """Основной цикл работы бота."""
        await self.initialize()
        logger.info("🚀 Бот запущен и готов к работе")
        
        try:
            while True:
                messages = self.generate_message()
                await self.send_request(messages)
                await asyncio.sleep(1)
        except KeyboardInterrupt:
            logger.info("👋 Бот остановлен пользователем")
        finally:
            if self.session:
                await self.session.close()

if __name__ == "__main__":
    bot = GaiaBot()
    asyncio.run(bot.run())
