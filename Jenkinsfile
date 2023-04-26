pipeline {
    agent { 
        label "docker-jenkins"
     }
    stages {
        stage('TESTE UNITARIO') {
            steps {
                docker run -v /home/jackson/workspace/PIPE-TOTVS:/tmp -v /tmp/output/:/bin/output/ totvsengpro/advpl-tlpp-code-analyzer
            }
        }
    }
}
