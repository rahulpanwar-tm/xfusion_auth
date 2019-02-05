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
            sh 'Ping 192.168.1.62'
          }
        }
      }
    }
  }
}