pipeline {
    agent { 
        label "docker-jenkins"
     }
    stages {
        stage('TESTE UNITARIO') {
            steps {
                sh 'git clone https://github.com/DevOpsdoCalor/CODE-TESTE.git'
            }
        }
    
            stage('TESTE UNITARIO') {
            steps {
               sh 'sudo docker run --rm -v /home/jackson/workspace/teste:/tmp -v /tmp/output/:/bin/output/ totvsengpro/advpl-tlpp-code-analyzer'
            }
        }
    }
}
