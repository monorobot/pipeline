---
AWSTemplateFormatVersion: '2010-09-09'
Description: 'Amazon EKS VPC'

Parameters:

  ClusterName:
    Description: The cluster name provided when the cluster was created.  If it is incorrect, nodes will not be able to join the cluster.
    Type: String

  VpcId:
    Type: String
    Description: The VPC to be used instead of creating a new one.
    Default: ""

  RouteTableId:
    Type: String
    Default: ""
    Description: Id of the RouteTable of the VPC to be used by subnets. This is used only when subnets are created into existing VPC.

  VpcBlock:
    Type: String
    Default: 192.168.0.0/16
    Description: The CIDR range for the VPC. This should be a valid private (RFC 1918) CIDR range. Used only when new VPC is created.

  Subnet01Block:
    Type: String
    Default: 192.168.64.0/20
    Description: CidrBlock for subnet 01 within the VPC

  Subnet02Block:
    Type: String
    Default: 192.168.80.0/20
    Description: CidrBlock for subnet 02 within the VPC

  Subnets:
    Description: The subnets where workers can be created.
    Type: String
    Default: ""

Metadata:
  AWS::CloudFormation::Interface:
    ParameterGroups:
      -
        Label:
          default: "EKS Cluster"
        Parameters:
          - ClusterName
      -
        Label:
          default: "Worker Network Configuration"
        Parameters:
          - VpcId
          - RouteTableId
          - VpcBlock
          - Subnet01Block
          - Subnet02Block
          - Subnets
Conditions:
  CreateVpc: !Equals [ !Ref VpcId, "" ]
  CreateSubnets: !Equals [ !Ref Subnets, "" ]

Resources:
  VPC:
    Type: "AWS::EC2::VPC"
    Condition: CreateVpc
    Properties:
      CidrBlock:  !Ref VpcBlock
      EnableDnsSupport: true
      EnableDnsHostnames: true
      Tags:
      - Key: Name
        Value: !Sub '${AWS::StackName}-VPC'

  InternetGateway:
    Type: "AWS::EC2::InternetGateway"
    Condition: CreateVpc

  VPCGatewayAttachment:
    Type: "AWS::EC2::VPCGatewayAttachment"
    Condition: CreateVpc
    Properties:
      InternetGatewayId: !Ref InternetGateway
      VpcId: !Ref VPC

  RouteTable:
    Type: "AWS::EC2::RouteTable"
    Condition: CreateVpc
    Properties:
      VpcId: !Ref VPC
      Tags:
      - Key: Name
        Value: Public Subnets
      - Key: Network
        Value: Public

  Route:
    DependsOn: VPCGatewayAttachment
    Condition: CreateVpc
    Type: "AWS::EC2::Route"
    Properties:
      RouteTableId: !Ref RouteTable
      DestinationCidrBlock: 0.0.0.0/0
      GatewayId: !Ref InternetGateway

  Subnet01:
    Type: "AWS::EC2::Subnet"
    Condition: CreateSubnets
    Metadata:
      Comment: Subnet 01
    Properties:
      AvailabilityZone:
        Fn::Select:
        - '0'
        - Fn::GetAZs:
            Ref: AWS::Region
      CidrBlock:
        Ref: Subnet01Block
      VpcId: !If [ CreateVpc, !Ref VPC,  !Ref VpcId ]
      Tags:
      - Key: Name
        Value: !Sub "${AWS::StackName}-Subnet01"

  Subnet02:
    Type: "AWS::EC2::Subnet"
    Condition: CreateSubnets
    Metadata:
      Comment: Subnet 02
    Properties:
      AvailabilityZone:
        Fn::Select:
        - '1'
        - Fn::GetAZs:
            Ref: AWS::Region
      CidrBlock:
        Ref: Subnet02Block
      VpcId: !If [ CreateVpc, !Ref VPC,  !Ref VpcId ]
      Tags:
      - Key: Name
        Value: !Sub "${AWS::StackName}-Subnet02"

  Subnet01RouteTableAssociation:
    Type: "AWS::EC2::SubnetRouteTableAssociation"
    Condition: CreateSubnets
    Properties:
      SubnetId: !Ref Subnet01
      RouteTableId: !If [ CreateVpc, !Ref RouteTable,  !Ref RouteTableId ]

  Subnet02RouteTableAssociation:
    Type: "AWS::EC2::SubnetRouteTableAssociation"
    Condition: CreateSubnets
    Properties:
      SubnetId: !Ref Subnet02
      RouteTableId: !If [ CreateVpc, !Ref RouteTable,  !Ref RouteTableId ]

Outputs:

  SubnetIds:
    Description: All subnets in the VPC
    Value:  !If [ CreateSubnets, !Join [ ",", [ !Ref Subnet01, !Ref Subnet02 ] ], !Ref Subnets ]

  VpcId:
    Description: The VPC Id
    Value: !If [ CreateVpc, !Ref VPC,  !Ref VpcId ]