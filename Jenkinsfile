pipeline {
    agent { 
        label "docker-jenkins"
     }
    stages {  
        stage('GIT CLONE') {
            steps {
                sh 'git fetch --all'
            }
      }     
        stage('TESTE UNITARIO') {
            steps {
               sh 'sudo docker run --rm -v /home/jackson/workspace/teste:/tmp -v /tmp/output/:/bin/output/ totvsengpro/advpl-tlpp-code-analyzer'
            }
        }
    }
}
