#!/usr/bin/php -q
<?php

	if(isset($argv[0])) unset($argv[0]);
	
	if(count($argv)){
		foreach($argv as $arg){
			if(is_file($arg)){
				$x = file_get_contents($arg);
				$w = unserialize($x);
				echo "[",$arg,"]\n";
				print_r($w);
				echo "\n";
			}
		}
	}

?>