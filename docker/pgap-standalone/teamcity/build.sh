BUILD_TYPE=%teamcity.build.branch%

echo "##teamcity[setParameter name='env.PGAP_BUILD_TYPE' value='${BUILD_TYPE}']"

./build-image.sh $PGAP_BUILD_TYPE
./save-image.sh $PGAP_BUILD_TYPE
./push-image.sh $PGAP_BUILD_TYPE
