require File.dirname(__FILE__) + '/../../test_helper'

class RemoteRealexTest < Test::Unit::TestCase
 
  def setup
    @gateway = RealexGateway.new(fixtures(:realex))

    @gateway_with_account = RealexGateway.new(fixtures(:realex_with_account))
  
    # Replace the card numbers with the test account numbers from Realex
    @visa            = credit_card('your-test-creditcard-no-here')
    @visa_declined   = credit_card('your-test-creditcard-no-here')
    @visa_referral_b = credit_card('your-test-creditcard-no-here')
    @visa_referral_a = credit_card('your-test-creditcard-no-here')
    @visa_coms_error = credit_card('your-test-creditcard-no-here')
    
    @mastercard            = credit_card('your-test-creditcard-no-here', {:type => 'master'})
    @mastercard_declined   = credit_card('your-test-creditcard-no-here', {:type => 'master'})
    @mastercard_referral_b = credit_card('your-test-creditcard-no-here', {:type => 'master'})
    @mastercard_referral_a = credit_card('your-test-creditcard-no-here', {:type => 'master'})
    @mastercard_coms_error = credit_card('your-test-creditcard-no-here', {:type => 'master'})
    
    @amount = 10000
  end
  
  def test_realex_authorize
    [ @visa, @mastercard ].each do |card|

      response = @gateway.authorize(@amount, card, 
        :order_id => generate_unique_id,
        :description => 'Test Realex authorize',
        :billing_address => {
          :zip => '90210',
          :country => 'US'
        }
      )
      assert_not_nil response
      assert_success response
      assert response.test?
      assert response.authorization.length > 0
      assert_equal 'Successful', response.message
    end      
  end
  
  def test_realex_authorize_and_capture
    [ @visa, @mastercard ].each do |card|

      auth_response = @gateway.authorize(@amount, card, 
        :order_id => generate_unique_id,
        :description => 'Test Realex authorize',
        :billing_address => {
          :zip => '90210',
          :country => 'US'
        }
      )
 
      assert_not_nil auth_response
      assert_success auth_response
      assert auth_response.test?
      assert auth_response.authorization.length > 0
      assert_equal 'Successful', auth_response.message
    
      capt_response = @gateway.capture(@amount, auth_response.authorization,
        :order_id => auth_response.params['orderid'],
        :pasref => auth_response.params['pasref'],
        :description => 'Test Realex capture'
      )

      assert_not_nil capt_response
      assert_success capt_response
      assert capt_response.test?
      assert_equal 'Successful', capt_response.message
      
    end      
  end
  
  
  def test_realex_authorize_and_void
    [ @visa, @mastercard ].each do |card|

      auth_response = @gateway.authorize(@amount, card, 
        :order_id => generate_unique_id,
        :description => 'Test Realex authorize',
        :billing_address => {
          :zip => '90210',
          :country => 'US'
        }
      )
 
      assert_not_nil auth_response
      assert_success auth_response
      assert auth_response.test?
      assert auth_response.authorization.length > 0
      assert_equal 'Successful', auth_response.message
    
      void_response = @gateway.void(auth_response.authorization,
        :order_id => auth_response.params['orderid'],
        :pasref => auth_response.params['pasref'],
        :description => 'Test Realex void'
      )

      assert_not_nil void_response
      assert_success void_response
      assert void_response.test?
      assert_equal 'Successful', void_response.message
      
    end      
  end
  
  
  def test_realex_purchase
    [ @visa, @mastercard ].each do |card|

      response = @gateway.purchase(@amount, card, 
        :order_id => generate_unique_id,
        :description => 'Test Realex Purchase',
        :billing_address => {
          :zip => '90210',
          :country => 'US'
        }
      )
      assert_not_nil response
      assert_success response
      assert response.test?
      assert response.authorization.length > 0
      assert_equal 'Successful', response.message
    end      
  end
  
  def test_realex_purchase_with_invalid_login
    gateway = RealexGateway.new(
      :login => 'invalid',
      :password => 'invalid'
    )
    response = gateway.purchase(@amount, @visa, 
      :order_id => generate_unique_id,
      :description => 'Invalid login test'
    )
      
    assert_not_nil response
    assert_failure response
    
    assert_equal '504', response.params['result']
    assert_equal "There is no such merchant id. Please contact realex payments if you continue to experience this problem.", response.params['message']
    assert_equal RealexGateway::ERROR, response.message
  end
  
  def test_realex_purchase_with_invalid_account

    response = @gateway_with_account.purchase(@amount, @visa, 
      :order_id => generate_unique_id,
      :description => 'Test Realex purchase with invalid acocunt'
    )
  
    assert_not_nil response
    assert_failure response
      
    assert_equal '506', response.params['result']
    assert_equal "There is no such merchant account. Please contact realex payments if you continue to experience this problem.", response.params['message']
    assert_equal RealexGateway::ERROR, response.message
  end
  
  def test_realex_purchase_declined

    [ @visa_declined, @mastercard_declined ].each do |card|

      response = @gateway.purchase(@amount, card,
        :order_id => generate_unique_id,
        :description => 'Test Realex purchase declined'
      )
      assert_not_nil response
      assert_failure response
      
      assert_equal '101', response.params['result']
      assert_equal response.params['message'], response.message
    end            

  end

  def test_realex_purchase_referral_b
    [ @visa_referral_b, @mastercard_referral_b ].each do |card|
  
      response = @gateway.purchase(@amount, card,
        :order_id => generate_unique_id,
        :description => 'Test Realex Referral B'
      )
      assert_not_nil response
      assert_failure response
      assert response.test?
      assert_equal '102', response.params['result']
      assert_equal RealexGateway::DECLINED, response.message
    end
  end

  def test_realex_purchase_referral_a
    [ @visa_referral_a, @mastercard_referral_a ].each do |card|
      
      response = @gateway.purchase(@amount, card,
        :order_id => generate_unique_id,
        :description => 'Test Realex Rqeferral A'
      )
      assert_not_nil response
      assert_failure response
      assert_equal '103', response.params['result']
      assert_equal RealexGateway::DECLINED, response.message
    end      
  
  end
  
  def test_realex_purchase_coms_error

    [ @visa_coms_error, @mastercard_coms_error ].each do |card|

      response = @gateway.purchase(@amount, card,
        :order_id => generate_unique_id,
        :description => 'Test Realex coms error'
      )
      
      assert_not_nil response
      assert_failure response
      
      assert_equal '205', response.params['result']
      assert_equal RealexGateway::BANK_ERROR, response.message
    end      
  
  end
  
  def test_realex_ccn_error
    @visa.number = 5
    
    response = @gateway.purchase(@amount, @visa, 
      :order_id => generate_unique_id,
      :description => 'Test Realex ccn error'
    )
    assert_not_nil response
    assert_failure response
    
    assert_equal '509', response.params['result']
    assert_equal "Invalid credit card length", response.params['message']
    assert_equal RealexGateway::ERROR, response.message
  end

  def test_realex_expiry_month_error
    @visa.month = 13
    
    response = @gateway.purchase(@amount, @visa, 
      :order_id => generate_unique_id,
      :description => 'Test Realex expiry month error'
    )
    assert_not_nil response
    assert_failure response
    
    assert_equal '509', response.params['result']
    assert_equal RealexGateway::ERROR, response.message
  end


  def test_realex_expiry_year_error
    @visa.year = 2005
    
    response = @gateway.purchase(@amount, @visa,
      :order_id => generate_unique_id,
      :description => 'Test Realex expiry year error'
    )
    assert_not_nil response
    assert_failure response
    
    assert_equal '509', response.params['result']
    assert_equal RealexGateway::ERROR, response.message
  end
  
  def test_invalid_credit_card_name
    @visa.first_name = ""
    @visa.last_name = ""
    
    response = @gateway.purchase(@amount, @visa, 
      :order_id => generate_unique_id,
      :description => 'test_chname_error'
    )
    assert_not_nil response
    assert_failure response

    assert_equal '502', response.params['result']
    assert_equal RealexGateway::ERROR, response.message
  end

  def test_cvn
    @visa_cvn = @visa.clone
    @visa_cvn.verification_value = "111"
    response = @gateway.purchase(@amount, @visa_cvn, 
      :order_id => generate_unique_id,
      :description => 'test_cvn'
    )
    assert_not_nil response
    assert_success response
    assert response.authorization.length > 0
  end
  
  def test_customer_number
    response = @gateway.purchase(@amount, @visa, 
      :order_id => generate_unique_id,
      :description => 'test_cust_num',
      :customer => 'my customer id'
    )
    assert_not_nil response
    assert_success response
    assert response.authorization.length > 0
  end
end
