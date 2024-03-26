#!/bin/bash

set -e

function get_owned_elbsv1() {
    aws elb describe-tags \
        --load-balancer-names $(aws elb describe-load-balancers --query "LoadBalancerDescriptions[*].LoadBalancerName" --output text) \
        --query "TagDescriptions[?Tags[?Key=='kubernetes.io/cluster/${CLUSTER_NAME}' &&Value=='owned']].LoadBalancerName" \
        --output text
}

function get_owned_elbsv2() {
    aws elbv2 describe-tags \
        --resource-arns $(aws elbv2 describe-load-balancers --query "LoadBalancers[*].LoadBalancerArn" --output text) \
        --query "TagDescriptions[?Tags[?Key=='kubernetes.io/cluster/${CLUSTER_NAME}' &&Value=='owned']].ResourceArn" \
        --output text
}

function get_owned_targetgroups() {
    aws elbv2 describe-tags \
        --resource-arns $(aws elbv2 describe-target-groups --query "TargetGroups[*].TargetGroupArn" --output text) \
        --query "TagDescriptions[?Tags[?Key=='kubernetes.io/cluster/${CLUSTER_NAME}' &&Value=='owned']].ResourceArn" \
        --output text
}

function get_owned_sgs() {
    aws ec2 describe-security-groups \
        --filters Name=tag:kubernetes.io/cluster/${CLUSTER_NAME},Values=owned \
        --query "SecurityGroups[*].GroupId" \
        --output text
}

function delete_list_of_resources() {
    local AWSCMD=${2}
    local LIST=$(echo ${3} | sed -e 's/\s/,/g')
    IFS=',' read -r -a RESOURCES <<< "${LIST}"
    for RESOURCE in "${RESOURCES[@]}"; do
        echo "Deleting resource ${1}: ${RESOURCE}"
        eval "${AWSCMD} ${RESOURCE}"
    done
}

test -n "${1}" || (echo "You must provide the cluster name as first arg" && exit -1)
CLUSTER_NAME=${1}

# Classic load balancers
CLASSIC_ELBs=$(get_owned_elbsv1 ${1})
if [[ -n "${CLASSIC_ELBs}" ]]; then
    delete_list_of_resources "ClassicELB" "aws elb delete-load-balancer --load-balancer-name" "${CLASSIC_ELBs}"
fi
while [[ -n "$(get_owned_elbsv1 ${1})" ]]; do sleep 10; done

# V2 load balancers
V2_ELBs=$(get_owned_elbsv2 ${1})
if [[ -n "${V2_ELBs}" ]]; then
    delete_list_of_resources "ELBv2" "aws elbv2 delete-load-balancer --load-balancer-arn" "${V2_ELBs}"
fi
while [[ -n "$(get_owned_elbsv2 ${1})" ]]; do sleep 10; done

# Target groups
TARGET_GROUPs=$(get_owned_targetgroups ${1})
if [[ -n "${V2_ELBs}" ]]; then
    delete_list_of_resources "TargetGroup" "aws elbv2 delete-target-group --target-group-arn" "${V2_ELBs}"
fi
while [[ -n "$(get_owned_targetgroups ${1})" ]]; do sleep 10; done

# Security groups
SGs=$(get_owned_sgs ${1})
if [[ -n "${SGs}" ]]; then
    delete_list_of_resources "SecurityGroup" "aws ec2 delete-security-group --group-id" "${SGs}"
fi
while [[ -n "$(get_owned_sgs ${1})" ]]; do sleep 10; done
