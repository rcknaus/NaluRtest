#!/bin/bash
. ../../pass_fail.sh

CWD=$(pwd)
didSimulationDiffAnywhere=0
didSimulationDiffAnywhereFirst=0
didSimulationDiffAnywhereSecond=0
localDiffOne=0.0;
localDiffTwo=0.0;

# determine tolerance
testTol=0.00000001
platform=`uname`
if [ "$platform" == 'Linux' ]; then
    testTol=0.0000000000000001
fi

# set the global diff
GlobalMaxSolutionDiff=-1000000.0

if [ -f $CWD/PASS ]; then
    # already ran this test
    didSimulationDiffAnywhere=0
else
    # run the first case
    mpiexec -np 2 ../../naluX -i variableDensNonUniform.i -o variableDensNonUniform.log
    determine_pass_fail $testTol "variableDensNonUniform.log" "variableDensNonUniform.norm" "variableDensNonUniform.norm.gold"
    didSimulationDiffAnywhereFirst="$?"
    localDiffOne=$GlobalMaxSolutionDiff
    if [ "$didSimulationDiffAnywhereFirst" -gt 0 ]; then
        didSimulationDiffAnywhere=1
    fi

    # run the second case
    mpiexec -np 2 ../../naluX -i variableDensNonIso.i -o variableDensNonIso.log
    determine_pass_fail $testTol "variableDensNonIso.log" "variableDensNonIso.norm" "variableDensNonIso.norm.gold"
    didSimulationDiffAnywhereSecond="$?"
    localDiffTwo=$GlobalMaxSolutionDiff
    if [ "$didSimulationDiffAnywhereSecond" -gt 0 ]; then
        didSimulationDiffAnywhere=1
    fi

    # check who is greater
    if [ $(echo " $localDiffOne > $localDiffTwo " | bc) -eq 1 ]; then
        GlobalMaxSolutionDiff=$localDiffOne
    else
        GlobalMaxSolutionDiff=$localDiffTwo
    fi
   
fi

# write the file based on final status
if [ "$didSimulationDiffAnywhere" -gt 0 ]; then
    PASS_STATUS=0
else
    PASS_STATUS=1
    echo $PASS_STATUS > PASS
fi

# report it; 30 spaces
GlobalPerformanceTimeFirst=`grep "STKPERF: Total Time" variableDensNonUniform.log  | awk '{print $4}'`
GlobalPerformanceTimeSecond=`grep "STKPERF: Total Time" variableDensNonIso.log  | awk '{print $4}'`
totalPerfTime=`echo "$GlobalPerformanceTimeFirst + $GlobalPerformanceTimeSecond" | bc `
if [ $PASS_STATUS -ne 1 ]; then
    echo -e "..variableDensMMS............. FAILED":" " $totalPerfTime " s" " max diff: " $GlobalMaxSolutionDiff
else
    echo -e "..variableDensMMS............. PASSED":" " $totalPerfTime " s"
fi

exit
