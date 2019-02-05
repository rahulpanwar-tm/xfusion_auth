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
            sh 'echo "Ping to a server"'
          }
        }
      }
    }
    stage('message print') {
      parallel {
        stage('message print') {
          steps {
            mail(subject: 'Hello Rahul', body: 'PFA', from: 'xfusiondonotreply@gmail.com', to: 'rahul.panwar@teramatrix.in')
          }
        }
        stage('ping') {
          steps {
            sh 'ping 192.168.1.55'
          }
        }
      }
    }
  }
}