// PM2 Configuration for Glaz Finance App
// Alternative deployment without Docker

module.exports = {
  apps: [
    {
      name: 'glaz-finance-backend',
      script: './backend/dist/index.js',
      cwd: './',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '1G',
      env: {
        NODE_ENV: 'production',
        PORT: 3002,
        DATABASE_URL: 'postgresql://glaz_user:glaz_password_2024@localhost:5432/glaz_finance',
        REDIS_URL: 'redis://localhost:6379'
      },
      env_production: {
        NODE_ENV: 'production',
        PORT: 3002
      },
      error_file: './logs/backend-error.log',
      out_file: './logs/backend-out.log',
      log_file: './logs/backend-combined.log',
      time: true
    },
    {
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
        PORT: 3001,
        REACT_APP_API_URL: 'http://localhost:3002'
      },
      env_production: {
        NODE_ENV: 'production',
        PORT: 3001
      },
      error_file: './logs/frontend-error.log',
      out_file: './logs/frontend-out.log',
      log_file: './logs/frontend-combined.log',
      time: true
    }
  ],

  deploy: {
    production: {
      user: 'glaz-deploy',
      host: 'YOUR_SERVER_IP',
      ref: 'origin/main',
      repo: 'https://github.com/Progress-collab/glaz-finance-app.git',
      path: '/c/glaz-finance-app',
      'pre-deploy-local': '',
      'post-deploy': 'npm install && npm run build && pm2 reload ecosystem.config.js --env production',
      'pre-setup': ''
    }
  }
};
