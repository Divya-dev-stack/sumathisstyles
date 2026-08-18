<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

header('Content-Type: application/json');

require_once 'db.php';

try {

    $title   = trim($_POST['title'] ?? '');
    $message = trim($_POST['message'] ?? '');
    $type    = strtolower(trim($_POST['type'] ?? 'general'));

    if ($title === '' || $message === '') {
        throw new Exception("Title and Message are required.");
    }

    $allowed = ['order','promotion','class','general'];

    if (!in_array($type, $allowed)) {
        $type = 'general';
    }

    if (!$conn) {
        throw new Exception("Database connection failed.");
    }

    $sql = "INSERT INTO notifications(title,message,type)
            VALUES (?,?,?)";

    $stmt = $conn->prepare($sql);

    if (!$stmt) {
        throw new Exception("Prepare Error : ".$conn->error);
    }

    $stmt->bind_param("sss",$title,$message,$type);

    if(!$stmt->execute()){
        throw new Exception("Execute Error : ".$stmt->error);
    }

    echo json_encode([
        "status"=>"success",
        "message"=>"Notification sent successfully.",
        "id"=>$stmt->insert_id
    ]);

    $stmt->close();

} catch(Exception $e){

    http_response_code(500);

    echo json_encode([
        "status"=>"error",
        "message"=>$e->getMessage()
    ]);

}