pipeline {
    agent any
    options {
        ansiColor('xterm')
    }

    stages {
        stage('Checkout Code') {
            steps {
                script {
                    checkout changelog: false, scm: [
                        $class: 'GitSCM', branches: [[name: "main" ]], 
                        extensions: [], userRemoteConfigs: [[credentialsId: 'GITLAB_TOKEN', 
                        url: 'https://github.com/j6wops/pipelines.git']]]
                }
            }
        }
        stage('Verification') {
            steps {
                script {
                    sh encoding: 'UTF-8', label: 'View Files', script: 'pwd && ls -lah'
                }
            }
        }

        stage('Build') {
            steps {
                script {
                    sh encoding: 'UTF-8', label: 'Build demo image', script: 'cd demo && docker build . -t j6wdev/demo:test --no-cache'
                    sh encoding: 'UTF-8', label: 'Push demo image', script: 'docker push j6wdev/demo:test --no-cache'
                }
            }
        }
    }
}