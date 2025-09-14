module.exports = {
  apps : [{
    name: 'glaz-finance-backend',
    script: './backend/index.js',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    env: {
      NODE_ENV: 'production',
      PORT: 80,
      DATABASE_URL: 'sqlite://C:/glaz-finance-app/database/glaz_finance.db',
      REDIS_URL: 'redis://localhost:6379',
      NODE_SKIP_PLATFORM_CHECK: '1'
    }
  }, {
    name: 'glaz-finance-frontend',
    script: 'npm',
    args: 'start',
    cwd: './frontend',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    env: {
      NODE_ENV: 'production',
      PORT: 443,
      REACT_APP_API_URL: 'http://195.133.47.134',
      NODE_SKIP_PLATFORM_CHECK: '1'
    }
  }]
};
