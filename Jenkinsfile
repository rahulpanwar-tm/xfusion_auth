pipeline {
    agent any
    parameters {
        string(name: 'PERSON', defaultValue: 'Mr Jenkins', description: 'Who should I say hello to?')

        text(name: 'BIOGRAPHY', defaultValue: '', description: 'Enter some information about the person')

        booleanParam(name: 'TOGGLE', defaultValue: true, description: 'Toggle this value')

        choice(name: 'CHOICE', choices: ['One', 'Two', 'Three'], description: 'Pick something')

        password(name: 'PASSWORD', defaultValue: 'SECRET', description: 'Enter a password')

        file(name: "FILE", description: "Choose a file to upload")
    
    }
   
    stages {
        stage("foo") {
            steps {
                script {
                    env.RELEASE_SCOPE = input message: 'User input required', ok: 'Release!',
                            parameters: [choice(name: 'RELEASE_SCOPE', choices: 'patch\nminor\nmajor', description: 'What is the release scope?')]
                            
                   
                                            if (env.RELEASE_SCOPE == 'major') {
                                                    mail(subject: 'Major Deployement in Exicom ', body: 'First Test case', from: 'xfusiondonotreply@gmail.com', to: 'rahul.panwar@teramatrix.in')
                                            }
                                            if (env.RELEASE_SCOPE == 'minor') {
                                                    mail(subject: 'minor Deployement in Exicom ', body: 'First Test case', from: 'xfusiondonotreply@gmail.com', to: 'rahul.panwar@teramatrix.in')
                                            }
                                            if (env.RELEASE_SCOPE == 'patch') {
                                                    mail(subject: 'patch Deployement in Exicom ', body: 'First Test case', from: 'xfusiondonotreply@gmail.com', to: 'rahul.panwar@teramatrix.in')
                                            }
                                            
                                            else {
                                                    echo 'Unknown Deployement process !!'
                                            }         
                            
                }
                echo "${env.RELEASE_SCOPE}"
                
            }
        }
        
        stage('push for input variable') {
          steps {
               script {
          
           input(message: 'Are you sure?', id: '1', ok: 'I agree')
            
               }
           
          
             script {
                                            if (env.input == 'master') {
                                                    echo 'I only execute on the master branch'
                                            } else {
                                                    echo 'I execute elsewhere'
                                            }
                                    }
          }
        }
         stage('Build') {
      parallel {
        stage('Build') {
          steps {
            echo 'Hello Rahul'
          }
        }
        stage('Message') {
          steps {
            echo 'Hello Rahul'
          }
        }
      
        
        stage('Ping to server') {
          steps {
            sh 'ping -c 4 192.168.1.55'
          
          }
        }
      }
         }
        
        stage('Development') {
            steps {
                echo "Hello ${params.PERSON}"

                echo "Biography: ${params.BIOGRAPHY}"

                echo "Toggle: ${params.TOGGLE}"

                echo "Choice: ${params.CHOICE}"

                echo "Password: ${params.PASSWORD}"
            }
        }
         stage('Building') {
            steps {
                echo "Hello ${params.PERSON}"

                echo "Biography: ${params.BIOGRAPHY}"

                echo "Toggle: ${params.TOGGLE}"

                echo "Choice: ${params.CHOICE}"

                echo "Password: ${params.PASSWORD}"
            }
        }
         stage('Unit Testing') {
            steps {
                echo "Hello Unit Testing Process done"
            
  
            }
        }
          stage('test3') {
                            steps {
                                    script {
                                            if (env.BRANCH_NAME == 'I agree') {
                                                    echo 'I only execute on the master branch'
                                            } else {
                                                    echo 'I execute elsewhere'
                                            }
                                    }
                            }
                    }
        
         stage('mail sender') {
          steps {
            mail(subject: 'Hello Rahul', body: 'PFA', from: 'xfusiondonotreply@gmail.com', to: 'rahul.panwar@teramatrix.in')
          }
        }
        
         
        
         stage('Functional Testing') {
            steps {
                echo "Hello Functional Testing Process done"
                
                
                timeout(5) {
    waitUntil {
       script {
         def r = sh script: 'ping -c 4 192.168.1.55', returnStatus: true
         return (r == 0);
       }
    }
}

 build job: 'auth_testing_new'  
            }
        }
    }
}