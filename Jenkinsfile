pipeline {
    agent { node { label 'AGENT-1' } }
    environment{
        //here if you create any variable you will have global access, since it is environment no need of def
        packageVersion = ''
    }   
    stages {
        stage('Deploy'){
            steps{
                echo "Deploying ..."
                echo "Version from Params : ${params.version}"
            }
        }
    }
    post{
        always{
            echo 'cleaning up workspace'
            //deleteDir()
            }
        }
}
