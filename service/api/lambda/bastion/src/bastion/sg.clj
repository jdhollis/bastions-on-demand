(ns bastion.sg
  (:require [cognitect.aws.client.api :as aws]
            [bastion.clients :as clients]
            [bastion.env :as env]
            [bastion.util :as util]))

(defn- authorize-ingress-to-bastion
  [security-group-id cidr-ip]
  (println "Authorizing ingress from" cidr-ip "to security group" security-group-id)
  (aws/invoke @clients/ec2
              {:op      :AuthorizeSecurityGroupIngress
               :request {:CidrIp     cidr-ip
                         :FromPort   22
                         :GroupId    security-group-id
                         :IpProtocol "tcp"
                         :ToPort     22}}))

(defn- authorize-ingress-via-https
  [security-group-id]
  (println "Authorizing ingress via HTTPS from security group" security-group-id)
  (aws/invoke @clients/ec2
              {:op      :AuthorizeSecurityGroupIngress
               :request {:GroupId       security-group-id
                         :IpPermissions [{:FromPort         443
                                          :IpProtocol       "tcp"
                                          :ToPort           443
                                          :UserIdGroupPairs [{:GroupId security-group-id}]}]}}))

(defn- authorize-bastion-ingress-to-default
  [security-group-id]
  (println "Authorizing ingress from" security-group-id "to default security group" env/cluster-vpc-default-security-group-id)
  (aws/invoke @clients/ec2
              {:op      :AuthorizeSecurityGroupIngress
               :request {:GroupId       env/cluster-vpc-default-security-group-id
                         :IpPermissions [{:IpProtocol       "-1"
                                          :UserIdGroupPairs [{:GroupId security-group-id}]}]}}))

(defn- revoke-bastion-ingress-to-default
  [security-group-id]
  (println "Revoking ingress from" security-group-id "to default security group" env/cluster-vpc-default-security-group-id)
  (aws/invoke @clients/ec2
              {:op      :RevokeSecurityGroupIngress
               :request {:GroupId       env/cluster-vpc-default-security-group-id
                         :IpPermissions [{:IpProtocol       "-1"
                                          :UserIdGroupPairs [{:GroupId security-group-id}]}]}}))

(defn ip-matches?
  [security-group-id cidr-ip]
  (println "Checking whether ingress IP matches" cidr-ip "for security group" security-group-id)
  (let [response (aws/invoke @clients/ec2
                             {:op      :DescribeSecurityGroups
                              :request {:GroupsIds [security-group-id]
                                        :Filters
                                                   [{:Name   "ip-permission.cidr"
                                                     :Values [cidr-ip]}]}})]
    (not (nil? (first (:SecurityGroups response))))))

(defn get-id-for
  [user]
  (println "Getting existing security group for" user)
  (let [response (aws/invoke @clients/ec2
                             {:op      :DescribeSecurityGroups
                              :request {:Filters
                                        [{:Name   "vpc-id"
                                          :Values [env/cluster-vpc-id]}
                                         {:Name   "group-name"
                                          :Values [(util/security-group-name user)]}]}})]
    (:GroupId (first (:SecurityGroups response)))))

(defn create-for
  [user cidr-ip]
  (println "Creating security group for" user "with ingress from" cidr-ip)
  (let [security-group (aws/invoke @clients/ec2
                                   {:op      :CreateSecurityGroup
                                    :request {:Description (str "Bastion access to " env/service-name " for " user)
                                              :GroupName   (util/security-group-name user)
                                              :VpcId       env/cluster-vpc-id}})
        security-group-id (:GroupId security-group)]
    (authorize-ingress-to-bastion security-group-id cidr-ip)
    (authorize-ingress-via-https security-group-id)
    (authorize-bastion-ingress-to-default security-group-id)
    security-group-id))

(defn delete-for
  [user]
  (if-let [security-group-id (get-id-for user)]
    (do
      (revoke-bastion-ingress-to-default security-group-id)
      (println "Deleting security group for" user)
      (aws/invoke @clients/ec2
                  {:op      :DeleteSecurityGroup
                   :request {:GroupId security-group-id}}))))
