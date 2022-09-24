// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;

contract VerifyNonceStorage {
    struct VNS{
        bool is_created;
        bool is_used;
        uint using_time;
        string user_simple_addr;
        address emit_contract;
    }
    uint[] public list_verify_nonce;
    mapping (uint => VNS) public infoOf;
    event VerifyNonceAdded(uint verify_nonce,string _user_simple_addr,address _emit_contract);

    function _set(uint verify_nonce,string memory _user_simple_addr,address _emit_contract) public {
        list_verify_nonce.push(verify_nonce);
        infoOf[verify_nonce]=VNS(true,true,block.timestamp,_user_simple_addr,_emit_contract);
        emit VerifyNonceAdded(verify_nonce,_user_simple_addr,_emit_contract);
    }

    function get(uint verify_nonce) public view returns (VNS memory) {
        return infoOf[verify_nonce];
    }

    function add(uint verify_nonce,string memory _user_simple_addr,address _emit_contract) public returns(bool){
        if (infoOf[verify_nonce].is_used==false){
            _set(verify_nonce,_user_simple_addr,_emit_contract);
            return true;
        }else{
            return false;
        }
        
    }

    function number_of_list_verify_nonce() public view returns (uint) {
        return list_verify_nonce.length;
    }
}