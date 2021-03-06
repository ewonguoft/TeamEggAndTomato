class ClientsController < ApplicationController
	attr_accessor :client, :account
  def new
  	@client=Client.new
  	@client.build_account
  	@client.build_address
	@client.build_profile

  end
  def create
  	@client=Client.create(params_client)
  	#@account=@client.build_account(params_account).save
	if @client.build_account(params_account).save
		@address=@client.build_address(params_address).save
		@profile=@client.build_profile.save
		render plain:  params_client.inspect + "\n" +params[:client].inspect + "\n" +
		params_address.inspect + #@client.fname.inspect + @address.line1.inspect #params[:client].inspect
		@account.inspect
	else
		@client.destroy
		render 'new'
	end
  end

  def sign_in
    render "sign_in"
  end

  def verify
    #render plain: params.inspect
    @account=Account.select('*').where(accountable_type: 'Client', username: params_account_sign_in[:username],
     password: params_account_sign_in[:password]).first
    #render plain: @account.inspect
    if @account!=nil
      #@client=client.find(0)
      session[:user_id]=@account.id
      if require_logged_in
        #render plain: "client login successfully"
        redirect_to home_path
        flash[:alert] = 'Client successful login'
        #redirect_to teen_offerings_url and return true
      end
    else
      flash[:notice] = 'wrong username/password'
      redirect_to '/clients/sign_in' and return false
    end
  end

  def sign_out
	reset_session
	redirect_to '/clients/sign_in'
  end

  private
  def params_profile
    params.require(:profile)
	permit(:address)
  end
  def params_client
  	params.require(:client).
  	permit(:fname, :lname, :birth_date, :cell_phone)
  end
  def params_address
  	params.require(:client).require(:address).
  	permit(:line1, :line2, :city, :state, :zip)
  end
  def params_account
  	params.require(:client).require(:account).
  	permit(:username, :password)
  end
  def params_account_sign_in
    params.require(:account).
    permit(:username, :password)
  end
end
