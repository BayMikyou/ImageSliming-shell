#!/usr/bin/env bash

# TINY_KEY用于调用 TINYPNG API
TINY_KEY=vdTujbsFyys8NDxCybJfxzzYxDQxgvqB
CURRENT_DIR="unknown"
OUTPUT_DIR=output

# 调用TinyPng API执行压缩
function compress() {
    local image=$1
    local compress_image_name=`echo ${image} | sed 's/ //g'`
    compress_image_name=`basename ${compress_image_name}`
    local tiny_response=`curl -s --user api:${TINY_KEY} --data-binary @"${image}" -i https://api.tinify.com/shrink`
    local tiny_response_code=$?
    if [[ ${tiny_response_code} != 0 ]]; then
        print_error_msg "当前网络异常..."
        return -1
    fi

     local download_url=`echo ${tiny_response} | awk -F '"' '{print $(NF-1)}'`
     curl -so ${CURRENT_DIR}/${OUTPUT_DIR}/${compress_image_name} ${download_url}
     local download_result=$?
     if [ ${download_result} != 0 ]; then
        print_error_msg "图片下载异常...: $image"
        return -1
     fi
}

# 压缩目录中所有.png的图片
function compress_dir() {
    local dir=$1
    local index=0

    for image in ${dir}/*
    do
        if [[ ${image} == *.png || ${image} == *.jpg || ${image} == *.jpeg ]]; then

            let index++
            print_warning_msg "正在压缩第${index}张图片, 请稍等..."
            compress "${image}"
            local compress_result=$?
            if [ ${compress_result} == 0 ]; then
                 print_success_msg "已经成功压缩了第${index}张图片: $image"
            else
                 print_error_msg "抱歉!压缩第${index}张图片出错: $image"
            fi

        fi
    done
}

# 打印error msg
function print_error_msg(){
    local msg=$1
    echo -e "\033[31m $msg \033[0m"
}

# 打印success msg
function print_success_msg(){
    local msg=$1
    echo -e "\033[33m $msg \033[0m"
}

# 打印warning msg
function print_warning_msg(){
    local msg=$1
    echo -e "\033[34m $msg \033[0m"
}

# trim
function trim(){
    echo "$1" | tr -d ' '
}

# 执行main函数
function main() {
    if [[ ${TINY_KEY} == "" ]]; then
        print_error_msg "TinyAPI不合法,请检查API参数"
        return -1
    fi

    CURRENT_DIR=`cd $(dirname ${BASH_SOURCE:-$0});pwd`
    rm -rf ${CURRENT_DIR}/${OUTPUT_DIR}
    mkdir ${CURRENT_DIR}/${OUTPUT_DIR}


    compress_dir ${CURRENT_DIR}
    local compress_dir_result=$?
    if [ ${compress_dir_result} != 0 ]; then
        print_error_msg "压缩失败，请检查相关日志"
        rm -rf ${CURRENT_DIR}/${OUTPUT_DIR}
        return -1
    fi

    print_success_msg "压缩完毕,请到output目录中获取压缩后的图片..."

    osascript -e 'tell application "Terminal" to quit' & exit
}

main