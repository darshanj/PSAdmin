Function Execute-Oracle-Sql ($connectionString, $query)
{
	try {
		[Reflection.Assembly]::LoadWithPartialName("Oracle.DataAccess")	| Out-null
		$connection = New-Object Oracle.DataAccess.Client.OracleConnection($connectionString) 
	}
	catch [Exception ex]
	{
		"Error connecting to Oracle"
	}
	$set = new-object system.data.dataset   
	$adapter = new-object system.data.oracleclient.oracledataadapter ($query, $connection) 
	$adapter.Fill($set) 
	$table = new-object system.data.datatable 
	$table = $set.Tables[0]
	#return table
	$table
}

Function Execute-Oracle-Sql-Direct ($server, $instance, $userid, $pwd, $query)
{
	$connectionstr = "Data Source=(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=$server)(PORT=1521)) `
		(CONNECT_DATA=(SERVICE_NAME=$instance)));User Id=$userid;Password=$pwd;"
	
	Execute-Oracle-Sql $connectionString $query
}


Export-ModuleMember -function *