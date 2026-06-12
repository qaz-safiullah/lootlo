const Request = require('../models/RequestModel');

const requestItem = async (req, res) => {
    const { itemId } = req.params;
    const requesterId = req.user.id;

    try {
        const item = await Request.getItemDetailsForRequest(itemId);
        if (!item) return res.status(404).json({ success: false, error: 'Item not found.' });
        if (item.status !== 'available') return res.status(400).json({ success: false, error: 'Item is no longer available.' });
        if (item.user_id === requesterId) return res.status(400).json({ success: false, error: 'You cannot request your own item.' });

        const hasActive = await Request.checkActiveRequest(itemId, requesterId);
        if (hasActive) return res.status(400).json({ success: false, error: 'You already have an active request.' });

        await Request.create(itemId, requesterId);
        res.status(201).json({ success: true, message: 'Request sent successfully!' });
    } catch (error) {
        res.status(500).json({ success: false, error: 'Server error while requesting item.' });
    }
};

const proposeTime = async (req, res) => {
    try {
        await Request.proposeTime(req.params.requestId, req.body.proposedTime, req.user.id);
        res.status(200).json({ success: true, message: 'Pickup time proposed to taker!' });
    } catch (error) {
        res.status(error.message === 'Unauthorized' ? 401 : 500).json({ success: false, error: error.message });
    }
};

const acceptProposal = async (req, res) => {
    try {
        await Request.acceptProposal(req.params.requestId, req.user.id);
        res.status(200).json({ success: true, message: 'Pickup confirmed! Item is now promised to you.' });
    } catch (error) {
        res.status(400).json({ success: false, error: error.message });
    }
};

const confirmHandshake = async (req, res) => {
    try {
        const result = await Request.processHandshake(req.params.requestId, req.user.id);
        if (result.completed) {
            return res.status(200).json({ success: true, message: 'Transaction Complete! +1 Community Score awarded.' });
        }
        res.status(200).json({ success: true, message: 'Your confirmation is logged. Waiting for the other party.' });
    } catch (error) {
        res.status(400).json({ success: false, error: error.message });
    }
};

const getReceivedRequests = async (req, res) => {
    try {
        const requests = await Request.getReceived(req.user.id);
        res.status(200).json({ success: true, data: requests });
    } catch (error) { 
        res.status(500).json({ success: false, error: error.message }); 
    }
};

const getMyRequests = async (req, res) => {
    try {
        const requests = await Request.getMy(req.user.id);
        res.status(200).json({ success: true, data: requests });
    } catch (error) { 
        res.status(500).json({ success: false, error: error.message }); 
    }
};

const cancelRequest = async (req, res) => {
    try {
        await Request.cancel(req.params.requestId);
        res.status(200).json({ success: true, message: 'Request cancelled.' });
    } catch (error) {
        res.status(500).json({ success: false, error: 'Error cancelling request' });
    }
};

const checkRequestStatus = async (req, res) => {
    try {
        const hasRequested = await Request.checkActiveRequest(req.params.itemId, req.user.id);
        res.status(200).json({ success: true, hasRequested });
    } catch (error) {
        res.status(500).json({ success: false, hasRequested: false });
    }
};

module.exports = { requestItem, proposeTime, acceptProposal, confirmHandshake, getReceivedRequests, getMyRequests, cancelRequest, checkRequestStatus };