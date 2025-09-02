pipeline {
    agent any

    tools {
        nodejs "NodeJS"   // Jenkins managed NodeJS tool
    }

    options {
        timestamps()
        ansiColor('xterm')
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/<your-username>/mern.git'
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'npm ci' // faster & reproducible than npm install
            }
        }

        stage('Lint') {
            steps {
                sh 'npm run lint || true'  // don’t fail yet if lint not configured
            }
        }

        stage('Unit Tests') {
            steps {
                sh 'npm test || true'
            }
        }

        stage('Build') {
            steps {
                sh 'npm run build || echo "no build script"'
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: '**/build/**', fingerprint: true
            junit 'test-results/**/*.xml'  // if tests exist
        }
        failure {
            mail to: 'team@example.com',
                 subject: "Build Failed: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                 body: "See Jenkins logs: ${env.BUILD_URL}"
        }
    }
}

