// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "./IERC20.sol";
//import "./Verify.sol" as veri;

contract Getup{
    struct Cheque_getup{
        string name;
        uint256 amount_achieved;
        uint256 amount_not_achieved;
        uint getup_time_limit;
        uint sig_after;
        uint sig_before;
        bool is_used;
        bool is_achieved;
        uint256 total_transfered;
        uint256 got_hongbao_amount;
    }
    struct SupplementaryCard{
        string name;
        uint use_after;
        uint use_before;
        bool is_used;
        bool have_been_created;//You can't directly find out if any key exists in a mapping, ever, because they all exist. creates a namespace in which all possible keys exist, and values are initialized to 0/false.
    }
    event Transfer(address from, address to, uint amount);
    event GetSupplementaryCard();
    event GetHongbao(uint256 amount);
    event SupplementaryCardUsed(SupplementaryCard card);
    event Log(string info);
    Cheque_getup[] public cheque_getups;
    IERC20 erc20;
    uint[] public supplementary_cards_ID;
    mapping (uint => SupplementaryCard) public _SupplementaryCards;

    address public _PreviousContractAddr;
    bool public _IS_REVERSE;
    address public _addr_ERC20;
    address public _signer;
    address public _receiver;
    string public _simple_addr;
    string public _SimpleAddrOfCretaionContract;
    string public _name;
    bytes32 public msg_hash;
    uint public _verify_nonce;//通过在监督前一天的下午生成随机数，第二天把随机数写在纸上或拍视频，防止作弊。

    uint public PercentPonus=100;
    uint public PercentWinningChance=100;

    uint public _INF=100000000000000;


    constructor(bool IS_REVERSE ,string memory name, address erc20_addr, string memory simple_addr,address signer,address receiver,string memory SimpleAddrOfCretaionContract,address PreviousContractAddr){
        _IS_REVERSE=IS_REVERSE;//填False：如早睡早起监督，要求实际值<limit。填True：如背英语监督，要求实际值>limit。
        _name=name;
        _addr_ERC20=erc20_addr;
        _receiver=receiver;
        erc20=IERC20(_addr_ERC20);
        _simple_addr=simple_addr;
        _signer=signer;
        _SimpleAddrOfCretaionContract=SimpleAddrOfCretaionContract;
        _PreviousContractAddr=PreviousContractAddr;
        //填时间日期要修改“gen_合约.py”的三处！！是三处！！
        cheque_getups.push(Cheque_getup('2022-8-29 7:00:00 Delay:24',5000,1000,700,1661727600,1661814000,false,false,0,0));
        cheque_getups.push(Cheque_getup('2022-8-30 7:00:00 Delay:24',5000,1000,700,1661814000,1661900400,false,false,0,0));
        cheque_getups.push(Cheque_getup('2022-8-31 7:00:00 Delay:24',5000,1000,700,1661900400,1661986800,false,false,0,0));
        cheque_getups.push(Cheque_getup('2022-9-1 7:00:00 Delay:24',5000,1000,700,1661986800,1662073200,false,false,0,0));
        cheque_getups.push(Cheque_getup('2022-9-2 7:00:00 Delay:24',5000,1000,700,1662073200,1662159600,false,false,0,0));
        //填时间日期要修改“gen_合约.py”的三处！！是三处！！
        _verify_nonce=random(99999999,95430382304);
    }
    function random(uint number,uint seed) public view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,seed))) % number;

        //return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty, msg.sender,block.coinbase,block.gaslimit,block.number,gasleft(),msg.data,tx.gasprice,block.basefee,seed))) % number;
    }
    function _CreatSupplementaryCard(uint card_id) internal{
        if(_SupplementaryCards[card_id].have_been_created==false){
            _SupplementaryCards[card_id]=SupplementaryCard("unll",block.timestamp,block.timestamp + 30 days,false,true);
            supplementary_cards_ID.push(card_id);
            emit GetSupplementaryCard();
        }else{
            emit Log("The Supplementary Card have been created before! ");
        }

    }
    function lottery(uint random_10000,uint percent_winning_chance,uint256 percent_bonus) internal returns(uint256){
        require(random_10000<=10000,"random_10000 must <=10000");

        //算是否发补签卡
        uint tmp=1000*percent_winning_chance/100;
        if (tmp>9999){
            //tmp too large
            tmp=5000;
        }
        tmp=9999-tmp;
        if(random_10000>tmp){
            //get a 补签卡
            _CreatSupplementaryCard(random_10000);
        }
        
        //算发多少红包
        uint256 hongbao=0;
        if(random_10000>0&&random_10000<0+3000*percent_winning_chance/100){
            //example:210
            hongbao+=random_10000/10*percent_bonus/100;
        }
        if(random_10000>10000 - 1000*percent_winning_chance/100 && random_10000<10000){
            //example:920
            hongbao+=random_10000/10*percent_bonus/100;
        }
        if(random_10000>10000 - 100*percent_winning_chance/100 &&random_10000<10000){
            //example:8700
            hongbao+=random_10000/10*percent_bonus/100*10;
        }
        return(hongbao);
    }


    function do_fetch_cheque(uint cheque_id, bytes memory SignedMessage, uint getup_time ,uint sig_time, uint order_supplementary_card,uint seed_int,uint verify_nonce) public virtual payable returns(Cheque_getup memory cheque_info){
        //verify_nonce: 第一次是constructor生成的随机数，之后是前一次fetch的seed_int
        msg_hash=keccak256(abi.encode(_simple_addr,sig_time,seed_int,getup_time,verify_nonce));
        require(verify(_signer,msg_hash,SignedMessage),"Invalid signature! ");
        require(verify_nonce==_verify_nonce,"Invalid verify nonce! ");
        require(sig_time>=cheque_getups[cheque_id].sig_after,"Too early to sign! sig_time<=cheque_getups[cheque_id].sig_after");
        require(!cheque_getups[cheque_id].is_used,"You have fetched! ");
        uint256 amount_to_transfer=0;
        
        //REVERSE!!
        if(_IS_REVERSE){
            getup_time=_INF-getup_time;
        }
        if(sig_time>cheque_getups[cheque_id].sig_before){
            //"Too late to sign! sig_time>=cheque_getups[cheque_id].sig_before"
            //use Supplementary Card
            uint id_supplementary_card=supplementary_cards_ID[order_supplementary_card];
            require(_SupplementaryCards[id_supplementary_card].is_used==false,"Have not supplementary card! Too late to sign!");
            require(sig_time<=_SupplementaryCards[id_supplementary_card].use_before,"Too late to use SupplementaryCard! ");
            require(sig_time>=_SupplementaryCards[id_supplementary_card].use_after,"Too ealry to use SupplementaryCard! ");
            _SupplementaryCards[id_supplementary_card].is_used=true;
            emit SupplementaryCardUsed(_SupplementaryCards[id_supplementary_card]);
        }
        if(getup_time<=cheque_getups[cheque_id].getup_time_limit){
            amount_to_transfer+=cheque_getups[cheque_id].amount_achieved;
            cheque_getups[cheque_id].is_achieved=true;
        }else{
            /*迟到也可以获得一定金额，
            获得金额数=未完成金额+（完成金额-未完成金额）*百分比
            百分比=75-late_time*3
            故：late_time大于25则获得金额=未完成金额
            */

            //有Bug：700和655之间是差了5分钟，而不是55分钟
            uint256 the_amount_not_achieved;
            uint late_time=getup_time-cheque_getups[cheque_id].getup_time_limit;
            the_amount_not_achieved=cheque_getups[cheque_id].amount_achieved-cheque_getups[cheque_id].amount_not_achieved;
            if(late_time>25){//防止减出负数
                the_amount_not_achieved=cheque_getups[cheque_id].amount_not_achieved;
            }else{
                the_amount_not_achieved=the_amount_not_achieved*(75-late_time*3)/100+cheque_getups[cheque_id].amount_not_achieved;
            }
            
            amount_to_transfer+=the_amount_not_achieved;
        }

        if (cheque_id>0&&cheque_getups[cheque_id].is_achieved==true&&cheque_getups[cheque_id-1].is_achieved==true){
            //连续达成奖励
            PercentWinningChance+=10;
            PercentPonus+=5;
        }
        if (cheque_getups[cheque_id].is_achieved==false){
            //未达成惩罚
            PercentWinningChance=90;
            PercentPonus=90;
        }
        if (cheque_id>0&&cheque_getups[cheque_id-1].is_used==false&&cheque_id>1){
            //昨天未签到惩罚
            PercentWinningChance=50;
            PercentPonus=50;
        }

        uint random_10000=random(10000,seed_int);
        uint256 hongbao=lottery(random_10000,PercentWinningChance,PercentPonus);
        emit GetHongbao(hongbao);
        cheque_getups[cheque_id].got_hongbao_amount=hongbao;
        amount_to_transfer+=hongbao;//Add 红包
        
        if (amount_to_transfer>0){
            if (erc20.balanceOf(address(this))<amount_to_transfer){
                //余额不足则转出全部余额
                amount_to_transfer=erc20.balanceOf(address(this));
            }
            erc20.transfer(_receiver,amount_to_transfer);
            emit Transfer(address(this),_receiver,amount_to_transfer);
            cheque_getups[cheque_id].total_transfered=amount_to_transfer;
        }
        
        cheque_getups[cheque_id].is_used=true;
        _verify_nonce=seed_int;
        return(cheque_getups[cheque_id]);
    }
    function CreatSupplementaryCard(bytes memory SignedMessage,uint sig_time,uint seed_int) public virtual{
        msg_hash=keccak256(abi.encode(_SimpleAddrOfCretaionContract,sig_time,seed_int,_simple_addr));
        require(verify(_signer,msg_hash,SignedMessage),"Invalid signature! ");
        //Bug 重入攻击 coded-Yes; tested_No
        //Bug 覆写攻击 coded-Yes; tested_No
        _CreatSupplementaryCard(seed_int);
    }
    function IncreaseDifficulty(uint cheque_id,uint new_getup_time) public virtual returns(bool){
        if(new_getup_time<cheque_getups[cheque_id].getup_time_limit){
            cheque_getups[cheque_id].getup_time_limit=new_getup_time;
            return(true);
        }else{
            return(false);
        }

    }
    function SetReceiver(address receiver) public virtual returns(bool){
        if(receiver!=_receiver){
            _receiver=receiver;
            return(true);
        }else{
            return(false);
        }
    }

    function hash_test(uint getup_time ,uint sig_time,uint buqianka,uint random_int) public virtual returns(bytes32){
        msg_hash=keccak256(abi.encode(_simple_addr,sig_time,random_int,getup_time,buqianka));
        return msg_hash;

    }    


    
    // 输入 签名地址，未被签名的数据，签名后的数据
    function verify(
        address _ValidSigner,
        bytes32 MessageHash,
        bytes memory _sig
    ) public pure returns (bool) {
        bytes32 messageHash = MessageHash;
        bytes32 ethSignMessageHash = getEthSignedMessageHash(messageHash);

        return recover(ethSignMessageHash, _sig) == _ValidSigner;
    }
/*
    function getMessageHash(string memory _message)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(_message));
    }
*/
    function getEthSignedMessageHash(bytes32 _massageHash)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _massageHash
                )
            );
    }

    function recover(bytes32 _ethSignMessageHash, bytes memory _sig)
        public
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = _split(_sig); // 非对称加密算法会把信息签名为rsv 3个变量，现在要将数据分割出这三个变量
        return ecrecover(_ethSignMessageHash, v, r, s); // 通过EVM的内部函数ecrecover获取被签名数据的签名地址
    }

    function _split(bytes memory _sig)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(_sig.length == 65, "invalid signature length");

        assembly {
            r := mload(add(_sig, 32)) // 使用add()来跳过前32位，使用mload来加载内存里4个字节的数据
            s := mload(add(_sig, 64))
            v := byte(0, mload(add(_sig, 96))) // 使用byte()来数据转换为1个字节
        }
    }

}