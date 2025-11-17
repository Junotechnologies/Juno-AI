import functions_framework
from google.cloud import bigquery
import json
from flask import jsonify

# Initialize BigQuery client
client = bigquery.Client()


@functions_framework.http
def predict_tens_level(request):
    """
    Cloud Function to predict TENS level using the trained BigQuery ML model.
    Expects a POST request with JSON body containing user parameters.
    """

    # Set CORS headers for the preflight request
    if request.method == 'OPTIONS':
        headers = {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'POST',
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Max-Age': '3600'
        }
        return ('', 204, headers)

    # Set CORS headers for the main request
    headers = {'Access-Control-Allow-Origin': '*'}

    if request.method != 'POST':
        return (jsonify({'error': 'Method not allowed. Use POST.'}), 405, headers)

    try:
        # Parse request data
        request_json = request.get_json(silent=True)
        if not request_json:
            return (jsonify({'error': 'Invalid JSON in request body'}), 400, headers)

        # Extract parameters with defaults
        user_id = request_json.get('user_id')  # Optional
        user_age = request_json.get('user_age', 28)
        user_cycle_length = request_json.get('user_cycle_length', 30)
        user_period_length = request_json.get('user_period_length', 5)
        is_period_day = request_json.get('is_period_day', False)
        is_ovulation_day = request_json.get('is_ovulation_day', False)
        current_pain_level = request_json.get('current_pain_level')  # Can be None
        current_flow_level = request_json.get('current_flow_level')  # Can be None
        has_medications = request_json.get('has_medications', False)
        medication_count = request_json.get('medication_count', 0)
        user_experience = request_json.get('user_experience', 'experienced_user')
        time_of_day = request_json.get('time_of_day', 'afternoon')
        previous_tens_level = request_json.get('previous_tens_level', 5)
        tens_mode = request_json.get('tens_mode', 'continuous')  # New parameter

        # Validate required parameters
        if not isinstance(user_age, int) or not (13 <= user_age <= 80):
            return (jsonify({'error': 'user_age must be an integer between 13 and 80'}), 400, headers)

        if not isinstance(user_cycle_length, int) or not (21 <= user_cycle_length <= 45):
            return (jsonify({'error': 'user_cycle_length must be an integer between 21 and 45'}), 400, headers)

        if not isinstance(user_period_length, int) or not (2 <= user_period_length <= 10):
            return (jsonify({'error': 'user_period_length must be an integer between 2 and 10'}), 400, headers)

        if not isinstance(is_period_day, bool):
            return (jsonify({'error': 'is_period_day must be a boolean'}), 400, headers)

        if not isinstance(is_ovulation_day, bool):
            return (jsonify({'error': 'is_ovulation_day must be a boolean'}), 400, headers)

        if current_pain_level is not None and (not isinstance(current_pain_level, int) or not (0 <= current_pain_level <= 10)):
            return (jsonify({'error': 'current_pain_level must be an integer between 0 and 10 or null'}), 400, headers)

        if current_flow_level is not None and (not isinstance(current_flow_level, int) or not (0 <= current_flow_level <= 5)):
            return (jsonify({'error': 'current_flow_level must be an integer between 0 and 5 or null'}), 400, headers)

        if not isinstance(has_medications, bool):
            return (jsonify({'error': 'has_medications must be a boolean'}), 400, headers)

        if not isinstance(medication_count, int) or medication_count < 0:
            return (jsonify({'error': 'medication_count must be a non-negative integer'}), 400, headers)

        if user_experience not in ['new_user', 'learning_user', 'experienced_user']:
            return (jsonify({'error': 'user_experience must be one of: new_user, learning_user, experienced_user'}), 400, headers)

        if time_of_day not in ['morning', 'afternoon', 'evening', 'night']:
            return (jsonify({'error': 'time_of_day must be one of: morning, afternoon, evening, night'}), 400, headers)

        if not isinstance(previous_tens_level, int) or not (0 <= previous_tens_level <= 10):
            return (jsonify({'error': 'previous_tens_level must be an integer between 0 and 10'}), 400, headers)

        if tens_mode not in ['continuous', 'burst', 'modulation', 'strength']:
            return (jsonify({'error': 'tens_mode must be one of: continuous, burst, modulation, strength'}), 400, headers)

                # Step 1: Predict TENS mode using the trained model
        mode_query = f"""
        SELECT predicted_tens_mode
        FROM ML.PREDICT(
          MODEL `junoplus-dev.junoplus_analytics.tens_mode_model`,
          (SELECT
            {user_age} as age,
            {user_cycle_length} as cycle_length,
            {user_period_length} as period_length,
            {str(is_period_day).lower()} as is_period_day,
            {str(is_ovulation_day).lower()} as is_ovulation_day,
            {current_pain_level if current_pain_level is not None else 'NULL'} as pain_level,
            {current_flow_level if current_flow_level is not None else 'NULL'} as flow_level,
            {str(has_medications).lower()} as has_medications,
            {medication_count} as medication_count,
            CASE
              WHEN '{user_experience}' = 'new_user' THEN 0
              WHEN '{user_experience}' = 'experienced_user' THEN 1
              WHEN '{user_experience}' = 'expert_user' THEN 2
              ELSE 1
            END as user_experience_encoded,
            CASE
              WHEN '{time_of_day}' = 'morning' THEN 0
              WHEN '{time_of_day}' = 'afternoon' THEN 1
              WHEN '{time_of_day}' = 'evening' THEN 2
              WHEN '{time_of_day}' = 'night' THEN 3
              ELSE 1
            END as time_of_day_encoded,
            {previous_tens_level} as previous_tens_level,
            2 as previous_heat_level
          )
        )
        """

        # Execute mode prediction
        mode_job = client.query(mode_query)
        mode_results = list(mode_job.result())
        if not mode_results:
            return (jsonify({'error': 'Mode prediction failed'}), 500, headers)

        predicted_mode = int(mode_results[0]['predicted_tens_mode'])

        # Step 2: Predict TENS level using the trained model
        level_query = f"""
        SELECT predicted_target_tens_level as tens_prediction
        FROM ML.PREDICT(
          MODEL `junoplus-dev.junoplus_analytics.tens_predictor_production_vertex`,
          (SELECT
            {user_age} as age,
            {user_cycle_length} as cycle_length,
            {user_period_length} as period_length,
            {str(is_period_day).lower()} as is_period_day,
            {str(is_ovulation_day).lower()} as is_ovulation_day,
            {current_pain_level if current_pain_level is not None else 5} as period_pain_level,
            {current_flow_level if current_flow_level is not None else 0} as flow_level,
            {str(has_medications).lower()} as has_pain_medication,
            {medication_count} as medication_count,
            1.5 as recent_medication_usage,
            CASE
              WHEN '{time_of_day}' = 'morning' THEN 9
              WHEN '{time_of_day}' = 'afternoon' THEN 14
              WHEN '{time_of_day}' = 'evening' THEN 19
              ELSE 22
            END as session_hour,
            EXTRACT(DAYOFWEEK FROM CURRENT_DATE()) as day_of_week,
            CASE
              WHEN '{user_experience}' = 'new_user' THEN 30
              WHEN '{user_experience}' = 'learning_user' THEN 60
              ELSE 180
            END as days_since_signup,
            {previous_tens_level} as initial_tens_level,
            {current_pain_level if current_pain_level is not None else 5} as input_pain_level
          )
        )
        """

        # Execute level prediction
        level_job = client.query(level_query)
        level_results = list(level_job.result())
        if not level_results:
            return (jsonify({'error': 'Level prediction failed'}), 500, headers)

        predicted_tens = float(level_results[0]['tens_prediction'])

        # Step 3: Predict heat level using the trained model
        heat_query = f"""
        SELECT predicted_target_heat_level as heat_prediction
        FROM ML.PREDICT(
          MODEL `junoplus-dev.junoplus_analytics.heat_predictor_production_vertex`,
          (SELECT
            {user_age} as age,
            {user_cycle_length} as cycle_length,
            {user_period_length} as period_length,
            {str(is_period_day).lower()} as is_period_day,
            {str(is_ovulation_day).lower()} as is_ovulation_day,
            {current_pain_level if current_pain_level is not None else 5} as period_pain_level,
            {current_flow_level if current_flow_level is not None else 0} as flow_level,
            {str(has_medications).lower()} as has_pain_medication,
            {medication_count} as medication_count,
            1.5 as recent_medication_usage,
            CASE
              WHEN '{time_of_day}' = 'morning' THEN 9
              WHEN '{time_of_day}' = 'afternoon' THEN 14
              WHEN '{time_of_day}' = 'evening' THEN 19
              ELSE 22
            END as session_hour,
            EXTRACT(DAYOFWEEK FROM CURRENT_DATE()) as day_of_week,
            CASE
              WHEN '{user_experience}' = 'new_user' THEN 30
              WHEN '{user_experience}' = 'learning_user' THEN 60
              ELSE 180
            END as days_since_signup,
            {previous_tens_level} as initial_tens_level,
            {current_pain_level if current_pain_level is not None else 5} as input_pain_level
          )
        )
        """

        # Execute heat prediction
        heat_job = client.query(heat_query)
        heat_results = list(heat_job.result())
        if not heat_results:
            return (jsonify({'error': 'Heat prediction failed'}), 500, headers)

        predicted_heat = float(heat_results[0]['heat_prediction'])

        # Step 2: Predict TENS level and heat level using existing models
        level_query = f"""
        SELECT
          predicted_target_tens_level as tens_prediction
        FROM ML.PREDICT(
          MODEL `junoplus-dev.junoplus_analytics.tens_predictor_production_vertex`,
          (SELECT
            {user_age} as age,
            {user_cycle_length} as cycle_length,
            {user_period_length} as period_length,
            {str(is_period_day).lower()} as is_period_day,
            {str(is_ovulation_day).lower()} as is_ovulation_day,
            {current_pain_level if current_pain_level is not None else 5} as period_pain_level,
            {current_flow_level if current_flow_level is not None else 0} as flow_level,
            {str(has_medications).lower()} as has_pain_medication,
            {medication_count} as medication_count,
            1.5 as recent_medication_usage,
            CASE
              WHEN '{time_of_day}' = 'morning' THEN 9
              WHEN '{time_of_day}' = 'afternoon' THEN 14
              WHEN '{time_of_day}' = 'evening' THEN 19
              ELSE 22
            END as session_hour,
            EXTRACT(DAYOFWEEK FROM CURRENT_DATE()) as day_of_week,
            CASE
              WHEN '{user_experience}' = 'new_user' THEN 30
              WHEN '{user_experience}' = 'learning_user' THEN 60
              ELSE 180
            END as days_since_signup,
            {previous_tens_level} as initial_tens_level,
            {current_pain_level if current_pain_level is not None else 5} as input_pain_level
          )
        )
        """

        # Execute level prediction
        level_job = client.query(level_query)
        level_results = list(level_job.result())
        if not level_results:
            return (jsonify({'error': 'Level prediction failed'}), 500, headers)

        predicted_tens = float(level_results[0]['tens_prediction'])
        
        # For heat prediction, use a simple heuristic since the model might not exist
        if current_pain_level and current_pain_level >= 8:
            predicted_heat = 3
        elif current_pain_level and current_pain_level >= 6:
            predicted_heat = 2
        elif is_period_day:
            predicted_heat = 2
        else:
            predicted_heat = 1

        # Step 3: Apply hierarchical logic
        if predicted_mode == 0:
            recommended_tens_level = 0  # TENS off when mode=0
        else:
            recommended_tens_level = round(max(1, min(10, predicted_tens)))

        recommended_heat_level = round(max(0, min(3, predicted_heat)))

        # Step 4: Calculate confidence and explanations
        confidence_score = 0.75  # Base confidence
        if is_period_day and current_pain_level and current_pain_level >= 7:
            confidence_score = 0.95
        elif is_period_day and current_pain_level and current_pain_level >= 4:
            confidence_score = 0.85
        elif user_experience == 'experienced_user':
            confidence_score = 0.80
        elif predicted_mode == 0:
            confidence_score = 0.90  # High confidence for off mode

        # Generate explanation
        if predicted_mode == 0:
            explanation = "TENS therapy not recommended at this time - consider heat therapy only"
        elif predicted_mode == 1 and is_period_day and current_pain_level and current_pain_level >= 8:
            explanation = "Low intensity TENS recommended for severe period pain"
        elif predicted_mode == 2 and is_period_day and current_pain_level and current_pain_level >= 6:
            explanation = "Medium intensity TENS recommended for moderate period pain"
        elif predicted_mode == 3 and is_period_day and current_pain_level and current_pain_level >= 6:
            explanation = "High intensity TENS recommended for significant period pain"
        elif is_period_day and current_pain_level and current_pain_level >= 8:
            explanation = "High period pain detected - stronger therapy recommended for effective relief"
        elif is_period_day and current_pain_level and current_pain_level >= 6:
            explanation = "Moderate period pain - adjusted therapy for menstrual comfort"
        elif is_period_day:
            explanation = "Period day detected - gentle therapy optimized for menstrual cycle"
        elif is_ovulation_day:
            explanation = "Ovulation day - therapy adjusted for mid-cycle comfort"
        elif has_medications and current_pain_level and current_pain_level >= 6:
            explanation = "Pain medication usage considered - complementary therapy level"
        elif user_experience == 'new_user':
            explanation = "Gentle introduction setting for new user comfort and safety"
        elif user_experience == 'experienced_user':
            explanation = "Personalized setting based on your therapy history and preferences"
        else:
            explanation = "Intelligent recommendation based on your profile and current context"

        # Additional guidance
        if predicted_mode == 0:
            guidance = "Focus on heat therapy and consider non-TENS pain management options"
        elif is_period_day and current_pain_level and current_pain_level >= 6:
            guidance = "Consider combining with heat therapy for enhanced relief"
        elif current_pain_level and current_pain_level >= 8:
            guidance = "Monitor comfort level and adjust as needed during session"
        elif user_experience == 'new_user':
            guidance = "Start with shorter sessions (15-20 minutes) to build tolerance"
        elif predicted_mode >= 2:
            guidance = "Ensure proper electrode placement for optimal effectiveness"
        else:
            guidance = "Adjust based on comfort and effectiveness during therapy"

        # Build response
        result_dict = {
            'recommended_tens_mode': predicted_mode,
            'recommended_tens_level': recommended_tens_level,
            'recommended_heat_level': recommended_heat_level,
            'confidence_score': confidence_score,
            'recommendation_explanation': explanation,
            'additional_guidance': guidance,
            'context_used': {
                'is_period_day': is_period_day,
                'is_ovulation_day': is_ovulation_day,
                'current_pain_level': current_pain_level,
                'has_medications': has_medications,
                'user_experience': user_experience,
                'time_of_day': time_of_day,
                'tens_mode': tens_mode,
                'predicted_mode': predicted_mode
            },
            'prediction_timestamp': '2025-01-01T00:00:00.000000',  # Placeholder
            'model_version': 'multi_model_prediction',
            'raw_mode_prediction': predicted_mode,
            'raw_tens_prediction': predicted_tens,
            'raw_heat_prediction': predicted_heat
        }

        # Return successful response
        return (jsonify(result_dict), 200, headers)

    except Exception as e:
        print(f"Error processing request: {str(e)}")
        return (jsonify({'error': f'Internal server error: {str(e)}'}), 500, headers)



        