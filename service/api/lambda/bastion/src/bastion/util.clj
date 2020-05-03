(ns bastion.util
  (:require [clojure.string :as string]
            [digest]
            [bastion.env :as env]))

(def ^:const ^:private started-by-max-length 36)            ; Per https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_RunTask.html

(defn user-hash
  [user]
  (let [hash (digest/sha-256 user)]
    (subs hash 0 (- started-by-max-length 1))))

(defn attachment-description
  [task]
  (let [task-arn (:taskArn task)
        attachment-id (:id (first (:attachments task)))
        identifier (str "attachment/" attachment-id)
        attachment-description (string/replace task-arn #"task/.*" identifier)]
    attachment-description))

(defn security-group-name
  [user]
  (str env/cluster-name "/" user))
