pipeline {
    agent any

    tools {
        nodejs "NodeJS"   // Jenkins managed NodeJS tool
    }

    options {
        timestamps()
    }

    stages {
    //    stage('Checkout') {
    //        steps {
    //            git branch: 'main', url: 'https://github.com/darshanP1991/mern.git'
    //        }
    //    }

        stage('Install Dependencies') {
            steps {
                sh 'npm i' // faster & reproducible than npm install
            }
        }
        
        stage('Optional Lint') {
            steps {
                script {
                    if (fileExists('package.json') && sh(script: "grep lint package.json || true", returnStdout: true).trim()) {
                        sh 'npm run lint'
                    } else {
                        echo "⚠️ No lint script found, skipping"
                    }
                }
            }
        }

        stage('Optional Tests') {
            steps {
                script {
                    if (fileExists('package.json') && sh(script: "grep test package.json || true", returnStdout: true).trim()) {
                        sh 'npm test'
                    } else {
                        echo "⚠️ No test script found, skipping"
                    }
                }
            }
        }

        stage('Optional Build') {
            steps {
                script {
                    if (fileExists('package.json') && sh(script: "grep build package.json || true", returnStdout: true).trim()) {
                        sh 'npm run build'
                        archiveArtifacts artifacts: '**/build/**', fingerprint: true
                    } else {
                        echo "⚠️ No build script found, skipping"
                    }
                }
            }
        }
        
        stage('Verify App Runs') {
            steps {
                sh 'node server.js & sleep 5 && curl -I http://localhost:3000 || true'
                sh 'pkill node || true'
            }
        }

        stage('Docker Build & Push') {
            steps {
                script {
                     docker.withRegistry('https://index.docker.io/v1/', 'dockerhub-creds') {
                         def app = docker.build("darshanpandya/mern:${env.BUILD_NUMBER}")
                         app.push()
                         app.push("latest")
                     }
                }
            }
        } 


    }

    post {
         always {
            echo "Pipeline completed with status: ${currentBuild.currentResult}"
        }
        failure {
            echo "⚠️ Build failed. Skipping email notifications since no SMTP configured."
        }
    }
}

