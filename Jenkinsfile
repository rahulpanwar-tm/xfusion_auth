pipeline {
  agent any
  stages {
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
        stage('push for input variable') {
          steps {
            input(message: 'Please Enter your name', id: '1', ok: '0')
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
        echo 'Hello Unit Testing Process done'
      }
    }
    stage('test3') {
      steps {
        script {
          if (env.BRANCH_NAME == 'master') {
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
        echo 'Hello Functional Testing Process done'
        timeout(time: 5) {
          waitUntil() {
            script {
              def r = sh script: 'ping -c 4 192.168.1.55', returnStatus: true
              return (r == 0)
            }

          }

        }

        build 'auth_testing_new'
      }
    }
  }
  parameters {
    string(name: 'PERSON', defaultValue: 'Mr Jenkins', description: 'Who should I say hello to?')
    text(name: 'BIOGRAPHY', defaultValue: '', description: 'Enter some information about the person')
    booleanParam(name: 'TOGGLE', defaultValue: true, description: 'Toggle this value')
    choice(name: 'CHOICE', choices: ['One', 'Two', 'Three'], description: 'Pick something')
    password(name: 'PASSWORD', defaultValue: 'SECRET', description: 'Enter a password')
    file(name: 'FILE', description: 'Choose a file to upload')
  }
}