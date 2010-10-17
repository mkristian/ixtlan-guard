lib_path = (Pathname(__FILE__).dirname.parent.expand_path + 'lib').to_s
$LOAD_PATH.unshift lib_path unless $LOAD_PATH.include?(lib_path)
