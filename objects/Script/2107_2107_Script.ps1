Param( [string] $path )
echo 'test'
return (get-filehash $path).Hash
