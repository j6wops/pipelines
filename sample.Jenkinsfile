def info(str) {
    echo "\033[1;33m[Info]  "+str+"\033[0m"
}

def error(str) {
    echo "\033[1;31m[Error]  "+str+"\033[0m"
}

def success(str) {
    echo "\033[1;32m[Success]  "+str+"\033[0m"
}


pipeline {
    agent any
    options {
        ansiColor('xterm')
    }

    stages {
        stage('Checkout Code') {
            steps {
                script {
                    BUILD_TRIGGER_BY = "${currentBuild.getBuildCauses()[0].shortDescription}"
                    echo "BUILD_TRIGGER_BY: ${BUILD_TRIGGER_BY}"
                    if  (env.gitlabBranch.equals(null)) {
                        env.gitlabBranch = "develop"
                        env.jtag="develop"
                        info "Setting Branch to "+env.gitlabBranch
                    }else{
                        env.jtag=env.gitlabBranch
                    }
                    checkout changelog: false, scm: [
                        $class: 'GitSCM', branches: [[name: "*/$env.gitlabBranch" ]], 
                        extensions: [], userRemoteConfigs: [[credentialsId: 'GITLAB_TOKEN', 
                        url: 'https://giteam.ap-gw.net/root/b2b-backend.git']]]
                }
            }
        }

        stage('BlackDuck Scan') {
            steps {
                script {
                    def scanDirDIND="/var/jenkins_home/tmp/$env.JOB_NAME"
                    def scanDirHOST="/home/ec2-user/jenkins/tmp/$env.JOB_NAME"
                    def composerDIR="/var/jenkins_home/tmp/composer-php8"
                    sh label: 'Prepare for Scan', script: "rm package.json -fr && rm -fr $scanDirDIND || true && cp -r ../$env.JOB_NAME $scanDirDIND"
                    sh label: 'Fix Permission DIND', script: "docker run --rm -v $scanDirHOST:/var/www/html j6wdev/builder:8.1 chmod 777 vendor -R || true"
                    sh label: 'Composer Install', script: "docker run --rm -v $composerDIR:/root/.composer -v $scanDirHOST:/var/www/html j6wdev/builder:8.1 composer update" //
                    sh label: 'Fix Permission DIND', script: "docker run --rm -v $scanDirHOST:/var/www/html j6wdev/builder:8.1 chmod 777 vendor -R || true"
                    // 
                    withCredentials([string(credentialsId: 'BLACKDUCK-TOKEN', variable: 'TOKEN')]) {
                        sh label: 'Start BlackDuck Scan', script: "curl -s -L https://detect.synopsys.com/detect7.sh | bash -s -- --blackduck.url=https://j6winc.app.blackduck.com --blackduck.api.token="+"$TOKEN"+" --detect.project.name=B2B-BE --detect.project.version.name=1.0 --detect.code.location.name=B2B-BE_1.0 --detect.detector.search.depth=10 --detect.project.version.distribution=INTERNAL --detect.excluded.detector.types=NPM --detect.source.path=$scanDirDIND"
                    }

                    //echo "$BUILD_NUMBER"
                    //currentBuild.getRawBuild().getExecutor().interrupt(Result.SUCCESS)
                    //sleep(1)
                }
            }
        }

        stage('Build Image') {
            steps {
                script {
                    sh label: 'Docker build', script: 'docker pull j6wdev/rel:b2b'
                    sh label: 'Docker build', script: 'echo "FROM j6wdev/rel:b2b" > Dockerfile'
                    sh label: 'Docker build', script: 'echo "COPY . ." >> Dockerfile'
                    sh label: 'Docker build', script: 'echo "RUN composer install --no-interaction --no-ansi --optimize-autoloader" >> Dockerfile'
                    //sh label: 'Docker build', script: 'rm composer.lock -fr || true'
                    sh label: 'Docker build', script: 'docker build -t j6wdev/j6w:b2b-be-'+env.jtag+' . --no-cache'
                    sh label: 'Docker push', script: 'docker push -q j6wdev/j6w:b2b-be-'+env.jtag
                }
            }
        }

        stage('Deploy') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'MYSQL_BUS_TICKETING', passwordVariable: 'J6W_DB_PASSWORD', usernameVariable: 'J6W_DB_USERNAME'), string(credentialsId: 'MYSQL_HOST', variable: 'J6W_DB_HOST'), usernamePassword(credentialsId: 'BUS_API_CLIENT', passwordVariable: 'J6W_CLIENT_SECRET', usernameVariable: 'J6W_CLIENT_ID'), string(credentialsId: 'BUS_API_APP_KEY', variable: 'J6W_APP_KEY'), string(credentialsId: 'DEPLOY_TOKEN', variable: 'JTLS'), usernamePassword(credentialsId: 'DOCKER', passwordVariable: 'DOCKER_PASS', usernameVariable: 'DOCKER_USER'), 
                usernamePassword(credentialsId: 'BUS_OAUTH', passwordVariable: 'J6W_OAUTH_PRIVATE', usernameVariable: 'J6W_OAUTH_PUBLIC')]) {
                    sh label: 'Docker login', script: 'docker $JTLS login -u "$DOCKER_USER" -p "$DOCKER_PASS"'
                        /*sh label: 'DEPLOY', script: 'docker $JTLS pull -q j6wdev/j6w:b2b-be-'+env.jtag+' && docker $JTLS service rm b2b-be-'+env.jtag+' || true && \
                        docker $JTLS service create -q --name=b2b-be-'+env.jtag+' --replicas=1 --network=proxy \
                        -e J6W_NEPHESH_API_URL=https://api.lab.mynt.xyz/ \
                        -e J6W_NEPHESH_API_CLIENT_ID="gYIB757RJqQ6RPsGzm1sBOAASl7NNlKL" \
                        -e J6W_NEPHESH_API_CLIENT_SECRET="0fj4NmJ9TpsQnKYvZ5BPzLNhOBQOWx2g" \
                        -e J6W_APP_NAME=B2B-BE \
                        -e J6W_APP_ENV=local \
                        -e J6W_APP_DEBUG=false \
                        -e J6W_APP_URL="http://localhost" \
                        -e J6W_APP_KEY=$J6W_APP_KEY \
                        -e J6W_DB_HOST=$J6W_DB_HOST \
                        -e J6W_DB_PORT=3306 \
                        -e J6W_DB_DATABASE=b2b-mynt \
                        -e J6W_DB_USERNAME="b2b-mynt" \
                        -e J6W_DB_PASSWORD="47Hs8DZ.O74ot6Wf" \
                        -e J6W_CLIENT_ID=$J6W_CLIENT_ID \
                        -e J6W_CLIENT_SECRET=$J6W_CLIENT_SECRET \
                        -e J6W_OAUTH_PUBLIC=$J6W_OAUTH_PUBLIC \
                        -e J6W_OAUTH_PRIVATE=$J6W_OAUTH_PRIVATE \
                        j6wdev/j6w:b2b-be-'+env.jtag*/

                    sh label: 'Image Pull', script: 'docker $JTLS pull -q j6wdev/j6w:b2b-be-'+env.jtag
                    sh label: 'Deploy Image', script: 'docker $JTLS service update -q --force --update-parallelism 1 --update-delay 10s b2b-be-'+env.jtag
                    sh label: 'Get Containers', script: 'docker $JTLS ps | grep b2b-be'
                }
            }
        }

        stage('Clean Workspace') {
            steps {
                //sh label: 'Clean Docker', script: 'docker system prune -a -f'
                cleanWs deleteDirs: true
            }
        }
    }
    
    post {
        success {
            sh label: 'success Message', script: '/var/jenkins_home/telegram.sh "B2B-BE PROJECT HAVE BEEN DEPLOYED. :-) https://b2b-be.dev.j6w.work"'
        }
        failure {
            sh label: 'failure Message', script: '/var/jenkins_home/telegram.sh "Failure to deploy PROJECT B2B-BE. :-("'

        }
        unstable {
            sh label: 'unstable Message', script: '/var/jenkins_home/telegram.sh "Unstable build for B2B-BE."'
        }
        cleanup {
            deleteDir()
        }
    }
}
