# 1. Determine Build Type
#BUILD_TYPE=%teamcity.build.branch%
#echo "##teamcity[setParameter name='env.PGAP_BUILD_TYPE' value='${BUILD_TYPE}']"

PGAP_BUILD_TYPE=$(git rev-parse --abbrev-ref HEAD)
echo $PGAP_BUILD_TYPE


# 2. Generate Container Image
./build-image.sh $PGAP_BUILD_TYPE

# 3. Save Container Image
./save-image.sh $PGAP_BUILD_TYPE

# 4. Push to hub.docker.com
./push-image.sh $PGAP_BUILD_TYPE
