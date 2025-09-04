pipeline {
    agent any

    tools {
        nodejs "NodeJS"   // Jenkins managed NodeJS tool
    }

    options {
       timestamps()
       ansiColor('xterm')
	   buildDiscarder(logRotator(numToKeepStr: '20'))
    }
	
    environment {
    	REGISTRY_URL   = 'https://index.docker.io/v1/'
    	REGISTRY_NS    = 'darshanpandya'
    	IMAGE_NAME     = 'mern'
    	DOCKER_CREDS   = 'dockerhub-creds'
    }

    stages {

        stage('Checkout') {
            steps {
		      checkout scm
                script {
              		// Compute basics
              		env.SHORT_SHA = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
              		env.DATE_TAG  = sh(script: "date +%Y.%m.%d", returnStdout: true).trim()
              		env.IMG       = "${env.REGISTRY_NS}/${env.IMAGE_NAME}"
        	   }
            }
        }

        stage('Install Dependencies') {
            steps {
                sh '''
              	     if [ -f package-lock.json ]; then
                		npm ci
              	     else
                		npm i
              	     fi
        	    '''
            }
        }

        stage('Quality Gates (parallel)') {
            parallel {
                stage('Optional Lint') {
                    steps {
                        script {
                            if (fileExists('package.json') && sh(script: "grep lint package.json || true", returnStdout: true).trim()) {
                                sh 'npm run lint'
                            } else {
                                echo "No lint script found, skipping"
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
                                echo "No test script found, skipping"
                            }
                        }
                    }
                }

                stage('Dependency Audit') {
                  steps {
                    sh '''
                      if [ -f package.json ]; then
                        npm audit --json || true
                        mkdir -p reports && npm audit --json > reports/npm-audit.json || true
                      fi
                    '''
                  }
                }


            }
        }    
        

        stage('Optional Build') {
            steps {
                script {
                    if (fileExists('package.json') && sh(script: "grep build package.json || true", returnStdout: true).trim()) {
                        sh 'npm run build'
                    } else {
                        echo "No build script found, skipping"
                    }
                }
            }
        }

        
        stage('Docker Build (multi tags)') {
          steps {
            script {
              // Build with BUILD_NUMBER, short SHA & date tags
              def tags = ["${env.BUILD_NUMBER}", "commit-${env.SHORT_SHA}", "${env.DATE_TAG}", "latest"]
              docker.withRegistry(env.REGISTRY_URL, env.DOCKER_CREDS) {
                def image = docker.build("${env.IMG}:${env.BUILD_NUMBER}")
                // Apply extra tags locally
                tags.findAll { it != "${env.BUILD_NUMBER}" }.each { t ->
                  sh "docker tag ${env.IMG}:${env.BUILD_NUMBER} ${env.IMG}:${t}"
                }
              }
            }
          }
        }

        stage('Image Security Scan (Trivy)') {
          steps {
            script {
              def tag = "${env.BUILD_NUMBER}"
              sh """
                docker run --rm \
                  -v /var/run/docker.sock:/var/run/docker.sock \
                  aquasec/trivy:latest image --quiet --ignore-unfixed --severity HIGH,CRITICAL --exit-code 1 \
                  ${env.IMG}:${tag}
              """
            }
          }
        }

        stage('Push Images') {
          when { expression { currentBuild.resultIsBetterOrEqualTo('SUCCESS') } }
          steps {
            script {
              def tags = ["${env.BUILD_NUMBER}", "commit-${env.SHORT_SHA}", "${env.DATE_TAG}", "latest"]
              docker.withRegistry(env.REGISTRY_URL, env.DOCKER_CREDS) {
                tags.each { t -> sh "docker push ${env.IMG}:${t}" }
              }
            }
          }
        }


    }

    post {
        always {
          // Publish whatever we produced
          archiveArtifacts artifacts: 'reports/**/*', allowEmptyArchive: true
          // If you emit JUnit XML during tests, uncomment:
          // junit 'reports/junit/**/*.xml'
          sh 'docker image prune -f || true'
          cleanWs()
        }
        failure {
          echo "Build failed (see logs)."
        }
        success {
          echo "Build succeeded  — Pushed ${env.IMG} with tags: ${env.BUILD_NUMBER}, commit-${env.SHORT_SHA}, ${env.DATE_TAG}, latest"
        }
    }
}
