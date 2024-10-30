#!/bin/bash

set -e

function get_owned_elbsv1() {
  FILTER="$@"
  aws elb describe-tags \
    --load-balancer-names $(aws elb describe-load-balancers --query "LoadBalancerDescriptions[*].LoadBalancerName" --output text) \
    --query "TagDescriptions[?Tags[?${FILTER}]].LoadBalancerName" \
    --output text
}

function get_owned_elbsv2() {
  FILTER="$@"
  aws elbv2 describe-tags \
    --resource-arns $(aws elbv2 describe-load-balancers --query "LoadBalancers[*].LoadBalancerArn" --output text) \
    --query "TagDescriptions[?Tags[?${FILTER}]].ResourceArn" \
    --output text
}

function get_owned_targetgroups() {
  FILTER="$@"
  aws elbv2 describe-tags \
    --resource-arns $(aws elbv2 describe-target-groups --query "TargetGroups[*].TargetGroupArn" --output text) \
    --query "TagDescriptions[?Tags[?${FILTER}]].ResourceArn" \
    --output text
}

function get_owned_sgs() {
  aws ec2 describe-security-groups \
    --filters Name=tag:kubernetes.io/cluster/${CLUSTER_NAME},Values=owned \
    --query "SecurityGroups[*].GroupId" \
    --output text
}

function delete_owned_s3_buckets() {
  for bucket in $(aws s3api list-buckets --query "Buckets[?starts_with(Name, '${CLUSTER_NAME}-image-registry')].Name" --output text); do
    result=$(aws s3api get-bucket-tagging --bucket ${bucket} --query "TagSet[?Key == 'kubernetes.io/cluster/${CLUSTER_NAME}'] | [0].Value")
    if [[ "$result" == '"owned"' ]]; then
      echo "Deleting ${bucket}"
      aws s3api delete-bucket --bucket ${bucket}
    fi
  done
}

function delete_list_of_resources() {
    local AWSCMD=${2}
    local RESOURCES=($(echo ${3} | tr -s ' '))
    for RESOURCE in "${RESOURCES[@]}"; do
      echo "Deleting resource ${1}: ${RESOURCE}"
      eval "${AWSCMD} ${RESOURCE}"
    done
}

test -n "${1}" || (echo "You must provide the cluster name as first arg" && exit -1)
CLUSTER_NAME=${1}
FILTER="(Key=='kubernetes.io/cluster/${CLUSTER_NAME}' && Value=='owned') || (Key=='elbv2.k8s.aws/cluster' && Value=='${CLUSTER_NAME}')"

# Classic load balancers
CLASSIC_ELBs=$(get_owned_elbsv1 ${FILTER})
if [[ -n "${CLASSIC_ELBs}" ]]; then
  echo "Deleting Classic ELBs: ${CLASSIC_ELBs}"
  delete_list_of_resources "ClassicELB" "aws elb delete-load-balancer --load-balancer-name" "${CLASSIC_ELBs}"
fi
while [[ -n "$(get_owned_elbsv1 ${FILTER})" ]]; do sleep 10; done

# V2 load balancers
V2_ELBs=$(get_owned_elbsv2 ${FILTER})
if [[ -n "${V2_ELBs}" ]]; then
  echo "Deleting V2 ELBs: ${V2_ELBs}"
  delete_list_of_resources "ELBv2" "aws elbv2 delete-load-balancer --load-balancer-arn" "${V2_ELBs}"
fi
while [[ -n "$(get_owned_elbsv2 ${FILTER})" ]]; do sleep 10; done

# Target groups
TARGET_GROUPs=$(get_owned_targetgroups ${FILTER})
if [[ -n "${TARGET_GROUPs}" ]]; then
  echo "Deleting TargetGroups: ${TARGET_GROUPs}"
  delete_list_of_resources "TargetGroup" "aws elbv2 delete-target-group --target-group-arn" "${TARGET_GROUPs}"
fi
while [[ -n "$(get_owned_targetgroups ${FILTER})" ]]; do sleep 10; done

# Security groups
SGs=$(get_owned_sgs)
if [[ -n "${SGs}" ]]; then
  echo "Deleting SecurityGroups: ${SGs}"
  delete_list_of_resources "SecurityGroup" "aws ec2 delete-security-group --group-id" "${SGs}"
fi
while [[ -n "$(get_owned_sgs)" ]]; do sleep 10; done

# S3 registry bucket
delete_owned_s3_buckets
