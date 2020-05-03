(defproject bastion "0.1.0-SNAPSHOT"
  :description "bastion"
  :dependencies [[org.clojure/clojure "1.10.0"]
                 [org.clojure/core.async "0.4.490"]
                 [com.cognitect.aws/api "0.8.171"]
                 [com.cognitect.aws/endpoints "1.1.11.475"]
                 [com.cognitect.aws/ec2 "684.2.380.0"]
                 [com.cognitect.aws/ecs "683.2.374.0"]
                 [com.amazonaws/aws-lambda-java-core "1.2.0"]
                 [cheshire "5.8.1"]
                 [digest "1.4.8"]]
  :jvm-opts ["-Dclojure.compiler.elide-meta=[:doc]"
             "-Dclojure.compiler.direct-linking=true"]
  :profiles {:uberjar {:aot         :all
                       :global-vars {*warn-on-reflection* true}}
             :create  {:main         bastion.create
                       :name         "create-bastion"
                       :uberjar-name "create-bastion.jar"}
             :destroy {:main         bastion.destroy
                       :name         "destroy-bastion"
                       :uberjar-name "destroy-bastion.jar"}})
