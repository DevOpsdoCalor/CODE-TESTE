pipeline {
    agent { 
        label "docker-jenkins"
     }
    stages {
        stage('TESTE UNITARIO') {
            steps {
               sh 'sudo docker run --rm -v /home/jackson/workspace/PIPE-TOTVS:/tmp -v /tmp/output/:/bin/output/ totvsengpro/advpl-tlpp-code-analyzer'
            }
        }
    }
}
