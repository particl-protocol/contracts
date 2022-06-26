import ENV ".env/development";

//abstraction over folder structure and possible env files
module {
  public let OWNER = ENV.OWNER;
  public let STORAGE_ACTOR = ENV.STORAGE_ACTOR;
  public let NNS_ACTOR = ENV.NNS_ACTOR;
}