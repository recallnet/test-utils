import { createPublicClient, http, defineChain } from 'viem';

const rpcUrl = 'http://127.0.0.1:8645';

const customChain = defineChain({
    id: 248163216,
    name: 'Recall',
    network: 'recall-chain',
    nativeCurrency: {
        name: 'Recall Token',
        symbol: 'REC',
        decimals: 18,
    },
    rpcUrls: {
        default: {
            http: [rpcUrl],
        },
        public: {
            http: [rpcUrl],
        },
    },
    blockExplorers: {
        default: {
            name: 'Recall Explorer',
            url: 'http://explorer.mycustomchain.com',
        },
    },
});

(async () => {
    const transport = http(rpcUrl, {
        onRequest: ({ body }) => {
            console.log('JSON-RPC Request:', JSON.stringify(body, null, 2));
        },
    });
    // Initialize the Viem client
    const client = createPublicClient({
        chain: customChain,
        transport,
    });

    console.log('Listening for new blocks...');

    // Start watching new blocks
    const unwatch = client.watchBlocks({
        onBlock: async block => {
            console.log(block.hash);
            for (const tx of block.transactions) {
                const receipt = await client.getTransactionReceipt({ hash: tx.hash });
                console.log(receipt);
            }
        },
        includeTransactions: true,
        pollingInterval: 1000,
        onError: error => {
            console.error('Error watching blocks:', error);
        },
    });

    // Gracefully handle termination signals
    process.on('SIGINT', () => {
        console.log('Stopping block watcher...');
        unwatch();
        process.exit();
    });
})();
