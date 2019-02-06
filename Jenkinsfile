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
            sh 'ping 192.168.1.55'
          }
        }
      }
    }
    stage('message print') {
      parallel {
        stage('mail sender') {
          steps {
            mail(subject: 'Hello Rahul', body: 'PFA', from: 'xfusiondonotreply@gmail.com', to: 'rahul.panwar@teramatrix.in')
          }
        }
        stage('Delete Workspace') {
          steps {
            cleanWs(cleanWhenSuccess: true, notFailBuild: true, skipWhenFailed: true)
          }
        }
        stage('error') {
          steps {
            fileExists 'deployement.sh'
          }
        }
        stage('cdxcvdcdx') {
          steps {
            build(propagate: true, wait: true, quietPeriod: 1, job: 'master_job')
          }
        }
      }
    }
  }
}