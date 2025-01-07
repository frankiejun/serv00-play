#!/bin/perl

$addflag=0;
$flag=0;
$content=qq{
#added by serv00-play begin
export TZ=Asia/Shanghai
export EDITOR=vim
export VISUAL=vim
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
alias l='ls -ltr'
alias pp='ps aux'
alias ss='cd ~/serv00-play && ./start.sh'
#added by serv00-play end
};

while(<>){
  if( /^#added by serv00-play begin/){
    $addflag=1;
    $flag=1;
    print $content, "\n";
  }else{
    if (/^#added by serv00-play end/){
      $flag=0;
    }else{
      print if $flag==0;
    }
  }
}

if( $addflag==0 ){
  print $content, "\n";
}