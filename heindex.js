require('dotenv').config();
const { exec } = require('child_process');
const { FaucetService } = require('./services/FaucetService.js');
const { WalletService } = require('./services/WalletService.js');
const { LogService } = require('./services/LogService.js');
const { FAUCET_CONFIG } = require('./config/config.js');
const { ProxyService } = require('./services/ProxyService.js');

// Эмодзи для улучшения визуального восприятия
const EMOJIS = {
    SUCCESS: '✅',
    ERROR: '❌',
    WALLET: '👛',
    PROXY: '🌐',
    LOADING: '⏳',
    MONEY: '💰',
    ROCKET: '🚀',
    WARNING: '⚠️'
};

async function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

async function displayLogo() {
    return new Promise((resolve, reject) => {
        exec('curl -s https://raw.githubusercontent.com/Mozgiii9/NodeRunnerScripts/refs/heads/main/logo.sh | bash', 
            (error, stdout, stderr) => {
                if (error) {
                    console.error(`${EMOJIS.ERROR} Ошибка при загрузке логотипа: ${error}`);
                    reject(error);
                }
                console.log(stdout);
                resolve();
            });
    });
}

async function displayStatistics(walletService, proxyService) {
    console.log('\n=================================');
    console.log(`${EMOJIS.WALLET} Всего кошельков: ${walletService.getTotalWallets()}`);
    console.log(`${EMOJIS.PROXY} Всего прокси: ${proxyService.getTotalProxies()}`);
    console.log(`${EMOJIS.MONEY} Сумма запроса: ${FAUCET_CONFIG.DEFAULT_AMOUNT}`);
    console.log('=================================\n');
}

async function main() {
    try {
        LogService.clearScreen();
        await displayLogo();
        
        const walletService = new WalletService();
        const proxyService = new ProxyService();

        // Загрузка кошельков и прокси
        await walletService.loadWallets('src/config/wallets.txt');
        await proxyService.loadProxies('src/config/proxies.txt');

        if (walletService.getTotalWallets() === 0) {
            throw new Error(`${EMOJIS.ERROR} Кошельки не найдены в файле wallets.txt`);
        }

        await displayStatistics(walletService, proxyService);

        while (true) {
            try {
                const currentAddress = walletService.getCurrentWallet();
                const currentProxy = proxyService.getNextProxy();

                await LogService.info(`${EMOJIS.WALLET} Обработка кошелька: ${currentAddress}`);
                await LogService.info(`${EMOJIS.PROXY} Используется прокси: ${currentProxy || 'без прокси'}`);

                const faucetService = new FaucetService(currentAddress, currentProxy);
                const result = await faucetService.requestFaucet();

                if (result.success) {
                    await LogService.success(`${EMOJIS.SUCCESS} Успешный запрос к крану`);
                } else {
                    await LogService.error(`${EMOJIS.ERROR} Ошибка запроса к крану`, result.error);
                }

                walletService.rotateWallet();
                
                await LogService.info(`${EMOJIS.LOADING} Ожидание ${FAUCET_CONFIG.RETRY_DELAY/1000} секунд...`);
                await sleep(FAUCET_CONFIG.RETRY_DELAY);

            } catch (error) {
                await LogService.error(`${EMOJIS.ERROR} Ошибка в основном цикле`, error);
                await sleep(FAUCET_CONFIG.RETRY_DELAY);
            }
        }
    } catch (error) {
        await LogService.error(`${EMOJIS.ERROR} Критическая ошибка`, error);
        process.exit(1);
    }
}

main();
