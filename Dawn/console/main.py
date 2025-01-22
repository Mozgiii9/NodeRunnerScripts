import os
import sys
import inquirer

from inquirer.themes import GreenPassion
from art import text2art
from colorama import Fore
from loader import config

from rich.console import Console as RichConsole
from rich.panel import Panel
from rich.table import Table
from rich import box
from rich.text import Text
from rich.layout import Layout
from datetime import datetime

sys.path.append(os.path.realpath("."))


class Console:
    MODULES = (
        "🔐 Регистрация",
        "🌱 Фарминг",
        "✅ Выполнение заданий",
        "🔄 Повторная верификация аккаунтов",
        "📊 Экспорт статистики",
        "🚪 Выход",
    )
    MODULES_DATA = {
        "🔐 Регистрация": "register",
        "🌱 Фарминг": "farm",
        "🚪 Выход": "exit",
        "📊 Экспорт статистики": "export_stats",
        "✅ Выполнение заданий": "complete_tasks",
        "🔄 Повторная верификация аккаунтов": "re_verify_accounts",
    }

    def __init__(self):
        self.rich_console = RichConsole()
        self.layout = Layout()

    def show_dev_info(self):
        os.system("cls" if os.name == "nt" else "clear")

        title = text2art("NodeRunner", font="small")
        styled_title = Text(title, style="bold cyan")

        current_time = datetime.now().strftime("%H:%M:%S")
        status_text = Text.assemble(
            ("🕒 ", "bold yellow"),
            (f"Время: {current_time}\n", "bold white"),
            ("🤖 ", "bold blue"),
            ("Статус: ", "bold white"),
            ("Активен", "bold green"),
        )

        dev_panel = Panel(
            Text.assemble(
                styled_title,
                "\n\n",
                status_text,
            ),
            border_style="cyan",
            expand=False,
            title="[bold green]🚀 Добро пожаловать[/bold green]",
            subtitle="[bold blue]Версия 1.0[/bold blue]"
        )

        self.rich_console.print(dev_panel)
        print()

    @staticmethod
    def prompt(data: list):
        answers = inquirer.prompt(data, theme=GreenPassion())
        return answers

    def get_module(self):
        questions = [
            inquirer.List(
                "module",
                message=Fore.LIGHTBLACK_EX + "📌 Выберите модуль",
                choices=self.MODULES,
            ),
        ]

        answers = self.prompt(questions)
        return answers.get("module")

    def display_info(self):
        stats_table = Table(
            title="📈 Статистика",
            box=box.ROUNDED,
            border_style="cyan",
            header_style="bold magenta",
        )
        stats_table.add_column("📊 Параметр", style="cyan", justify="right")
        stats_table.add_column("📋 Значение", style="green")

        if config.redirect_settings.enabled:
            stats_table.add_row("📧 Режим перенаправления", "✅ Включен")
            stats_table.add_row("📨 Email для перенаправления", config.redirect_settings.email)

        stats_table.add_row("👥 Аккаунтов для регистрации", f"[bold blue]{str(len(config.accounts_to_register))}[/bold blue]")
        stats_table.add_row("🌱 Аккаунтов для фарминга", f"[bold green]{str(len(config.accounts_to_farm))}[/bold green]")
        stats_table.add_row("🔄 Аккаунтов для верификации", f"[bold yellow]{str(len(config.accounts_to_reverify))}[/bold yellow]")
        stats_table.add_row("⚡ Потоков", f"[bold cyan]{str(config.threads)}[/bold cyan]")
        stats_table.add_row(
            "⏱️ Задержка перед стартом",
            f"[bold red]{config.delay_before_start.min}[/bold red] - [bold red]{config.delay_before_start.max}[/bold red] сек",
        )

        system_panel = Panel(
            stats_table,
            expand=False,
            border_style="green",
            title="[bold yellow]⚙️ Системная информация[/bold yellow]",
            subtitle="[bold cyan]↑↓ Используйте стрелки для навигации[/bold cyan]",
        )
        
        self.rich_console.print(system_panel)

    def build(self) -> None:
        self.show_dev_info()
        self.display_info()

        module = self.get_module()
        config.module = self.MODULES_DATA[module]

        if config.module == "exit":
            self.rich_console.print("[bold red]👋 До свидания![/bold red]")
            exit(0)
