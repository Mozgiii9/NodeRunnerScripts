import aiohttp
import asyncio
import random
import os
import logging
import sys
from datetime import datetime
from typing import List, Dict, Optional
from dataclasses import dataclass
from aiohttp import ClientTimeout

# Настройка логирования
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
    handlers=[
        logging.StreamHandler(sys.stdout),
        logging.FileHandler('gaia_domain_bot.log')
    ]
)
logger = logging.getLogger(__name__)

@dataclass
class BotConfig:
    """Конфигурация бота."""
    node_id: str
    api_key: str
    num_threads: int
    retry_count: int = 3
    retry_delay: int = 5
    timeout: int = 300
    base_url: str = "gaia.domains"

    @property
    def api_url(self) -> str:
        return f"https://{self.node_id}.{self.base_url}/v1/chat/completions"

    @property
    def headers(self) -> Dict[str, str]:
        return {
            "Authorization": f"Bearer {self.api_key}",
            "Accept": "application/json",
            "Content-Type": "application/json"
        }

class GaiaDomainBot:
    def __init__(self):
        """Инициализация бота с конфигурацией."""
        self.config = self._load_config()
        self.roles: List[str] = []
        self.phrases: List[str] = []
        self.sessions: List[Optional[aiohttp.ClientSession]] = []
        self.timeout = ClientTimeout(total=self.config.timeout)

    def _load_config(self) -> BotConfig:
        """Загрузка конфигурации из переменных окружения."""
        try:
            return BotConfig(
                node_id=os.getenv("NODE_ID", ""),
                api_key=os.getenv("GAIA_API_KEY", ""),
                num_threads=int(os.getenv("NUM_THREADS", "1")),
                retry_count=int(os.getenv("RETRY_COUNT", "3")),
                retry_delay=int(os.getenv("RETRY_DELAY", "5")),
                timeout=int(os.getenv("TIMEOUT", "300"))
            )
        except ValueError as e:
            logger.error(f"❌ Ошибка конфигурации: {e}")
            sys.exit(1)

    async def initialize(self) -> None:
        """Инициализация бота и создание сессий."""
        try:
            self.roles = self._load_from_file("roles.txt")
            self.phrases = self._load_from_file("phrases.txt")
            self.sessions = [aiohttp.ClientSession() for _ in range(self.config.num_threads)]
            logger.info(f"✅ Бот инициализирован с {self.config.num_threads} потоками")
        except Exception as e:
            logger.error(f"❌ Ошибка инициализации: {e}")
            sys.exit(1)

    def _load_from_file(self, file_name: str) -> List[str]:
        """Загрузка данных из файла с валидацией."""
        try:
            with open(file_name, "r") as file:
                data = [line.strip() for line in file.readlines() if line.strip()]
                if not data:
                    raise ValueError(f"Файл {file_name} пуст")
                return data
        except FileNotFoundError:
            logger.error(f"❌ Файл {file_name} не найден!")
            sys.exit(1)

    def _generate_message(self) -> List[Dict[str, str]]:
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

    async def _send_request(self, worker_id: int, messages: List[Dict[str, str]]) -> None:
        """Отправка запроса к API с обработкой ошибок."""
        session = self.sessions[worker_id]
        for attempt in range(self.config.retry_count):
            try:
                async with session.post(
                    self.config.api_url,
                    json={"messages": messages},
                    headers=self.config.headers,
                    timeout=self.timeout
                ) as response:
                    if response.status == 200:
                        result = await response.json()
                        self._log_success(worker_id, messages[0]["content"], result)
                        return
                    else:
                        logger.warning(f"⚠️ Воркер {worker_id}, попытка {attempt + 1}/{self.config.retry_count}: Статус {response.status}")
            
            except asyncio.TimeoutError:
                logger.warning(f"⚠️ Воркер {worker_id}, попытка {attempt + 1}/{self.config.retry_count}: Таймаут")
            except Exception as e:
                logger.error(f"❌ Воркер {worker_id}, попытка {attempt + 1}/{self.config.retry_count}: Ошибка: {e}")
            
            if attempt < self.config.retry_count - 1:
                await asyncio.sleep(self.config.retry_delay)

    def _log_success(self, worker_id: int, question: str, result: Dict) -> None:
        """Логирование успешного ответа."""
        response = result["choices"][0]["message"]["content"]
        logger.info(f"🤖 Воркер {worker_id}")
        logger.info(f"📤 Вопрос: {question}")
        logger.info(f"📥 Ответ: {response}")
        logger.info("=" * 50)

    async def _worker(self, worker_id: int) -> None:
        """Рабочий процесс для каждого потока."""
        logger.info(f"🚀 Воркер {worker_id} запущен")
        while True:
            try:
                messages = self._generate_message()
                await self._send_request(worker_id, messages)
                await asyncio.sleep(3)
            except Exception as e:
                logger.error(f"❌ Воркер {worker_id} ошибка: {e}")
                await asyncio.sleep(5)

    async def run(self) -> None:
        """Запуск бота со всеми рабочими потоками."""
        await self.initialize()
        logger.info("🎯 Запуск рабочих потоков...")
        
        try:
            workers = [self._worker(i) for i in range(self.config.num_threads)]
            await asyncio.gather(*workers)
        except KeyboardInterrupt:
            logger.info("👋 Бот остановлен пользователем")
        finally:
            for session in self.sessions:
                if session:
                    await session.close()

if __name__ == "__main__":
    bot = GaiaDomainBot()
    asyncio.run(bot.run())
