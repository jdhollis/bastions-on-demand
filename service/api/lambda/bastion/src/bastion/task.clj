(ns bastion.task
  (:require [clojure.string :as string]
            [cognitect.aws.client.api :as aws]
            [bastion.clients :as clients]
            [bastion.eni :as eni]
            [bastion.env :as env]
            [bastion.util :as util]))

(defn- bastion-task
  [task]
  (let [attachment-description (util/attachment-description task)]
    {:task-arn               (:taskArn task)
     :attachment-description attachment-description
     :bastion-ip             (eni/get-public-ip attachment-description)}))

(defn get-for
  [user]
  (println "Getting running bastion for" user)
  (let [list-tasks (aws/invoke @clients/ecs
                               {:op      :ListTasks
                                :request {:cluster   env/cluster-name
                                          :startedBy (util/user-hash user)}})
        task-arns (:taskArns list-tasks)]
    (if (> (count task-arns) 0)
      (if-let [describe-tasks (aws/invoke @clients/ecs
                                          {:op      :DescribeTasks
                                           :request {:cluster env/cluster-name
                                                     :tasks   task-arns}})]
        (let [task (first (:tasks describe-tasks))]
          (bastion-task task))
        nil))))

(defn run-for
  [user security-group-id]
  (println "Running bastion for" user)
  (let [response (aws/invoke @clients/ecs
                             {:op      :RunTask
                              :request {:cluster              env/cluster-name
                                        :taskDefinition       env/task-family
                                        :count                1
                                        :startedBy            (util/user-hash user)
                                        :launchType           "FARGATE"
                                        :networkConfiguration {:awsvpcConfiguration
                                                               {:subnets        (string/split env/cluster-subnet-ids #",")
                                                                :securityGroups [security-group-id]
                                                                :assignPublicIp "ENABLED"}}
                                        :overrides            {:containerOverrides
                                                               [{:name        env/container-name
                                                                 :environment [{:name  "USER_NAME"
                                                                                :value user}]}]}}})
        task (first (:tasks response))]
    (bastion-task task)))

(defn stop-for
  [user task]
  (println "Stopping bastion for" user)
  (aws/invoke @clients/ecs
              {:op      :StopTask
               :request {:cluster env/cluster-name
                         :task    (:task-arn task)
                         :reason  "Requested by user"}})
  (eni/wait-for-deletion (:attachment-description task)))
